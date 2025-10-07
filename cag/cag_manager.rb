require 'set'
require './cag/knowledge_graph_interface.rb'
require './print.rb'

# CAG Manager to coordinate context-aware generation operations
class CAGManager
  def initialize(knowledge_graph_config, entity_extractor_config, cag_config = {})
    @knowledge_graph = create_knowledge_graph(knowledge_graph_config)
    @entity_extractor = create_entity_extractor(entity_extractor_config)
    @cag_config = {
      max_context_depth: cag_config[:max_context_depth] || 2,
      max_context_nodes: cag_config[:max_context_nodes] || 20,
      entity_types: cag_config[:entity_types] || ['ip_address', 'url', 'hash', 'filename', 'port'],
      enable_cross_reference: cag_config[:enable_cross_reference] || true,
      enable_caching: cag_config[:enable_caching] || false
    }
    @cache = {} if @cag_config[:enable_caching]
    @initialized = false
  end

  def setup
    return if @initialized

    Print.info "Initializing CAG Manager..."

    # Connect to knowledge graph
    unless @knowledge_graph.connected?
      Print.info "Connecting to knowledge graph..."
      @knowledge_graph.connect
      unless @knowledge_graph.connected?
        Print.err "Failed to connect to knowledge graph"
        return false
      end
    end

    @initialized = true
    Print.info "CAG Manager initialized successfully"
    true
  end

  def extract_entities(text, entity_types = nil)
    Print.info "Extracting entities from text..."
    entity_types ||= @cag_config[:entity_types]

    begin
      # Use entity extractor if available, otherwise fall back to basic extraction
      if @entity_extractor.respond_to?(:extract_entities)
        entities = @entity_extractor.extract_entities(text, entity_types)
      else
        # Fall back to basic extraction from knowledge graph interface
        entities = @knowledge_graph.extract_entities_from_text(text, entity_types)
      end

      Print.info "Extracted #{entities.length} entities"
      entities
    rescue => e
      Print.err "Error extracting entities: #{e.message}"
      Print.err e.backtrace.inspect
      []
    end
  end

  def expand_context_with_entities(entities, max_depth = nil, max_nodes = nil)
    unless @initialized
      setup unless setup
      return []
    end

    max_depth ||= @cag_config[:max_context_depth]
    max_nodes ||= @cag_config[:max_context_nodes]

    Print.info "Expanding context with #{entities.length} entities..."

    begin
      context_nodes = []
      processed_nodes = Set.new

      entities.each do |entity|
        entity_context = expand_entity_context(entity, max_depth, max_nodes, processed_nodes)
        context_nodes.concat(entity_context)
      end

      # Remove duplicates and limit total nodes
      unique_context_nodes = context_nodes.uniq { |node| node[:id] }
      limited_context_nodes = unique_context_nodes.take(max_nodes)

      Print.info "Expanded context to #{limited_context_nodes.length} nodes"
      limited_context_nodes
    rescue => e
      Print.err "Error expanding context: #{e.message}"
      Print.err e.backtrace.inspect
      []
    end
  end

  def get_context_for_query(query, max_depth = nil, max_nodes = nil)
    unless @initialized
      setup unless setup
      return nil
    end

    # Check cache first
    cache_key = "query:#{query.hash}"
    if @cag_config[:enable_caching] && @cache.key?(cache_key)
      Print.debug "Using cached CAG results for query: #{query[0..50]}..."
      return @cache[cache_key]
    end

    max_depth ||= @cag_config[:max_context_depth]
    max_nodes ||= @cag_config[:max_context_nodes]

    Print.info "Getting context for query: #{query[0..50]}..."

    begin
      # Extract entities from query
      entities = extract_entities(query)

      # Expand context with entities
      context_nodes = expand_context_with_entities(entities, max_depth, max_nodes)

      # Also search for direct nodes matching the query
      search_results = @knowledge_graph.search_nodes(query, max_nodes / 2)
      context_nodes.concat(search_results) if search_results

      # Remove duplicates and limit
      unique_context_nodes = context_nodes.uniq { |node| node[:id] }
      limited_context_nodes = unique_context_nodes.take(max_nodes)

      # Format context for display
      formatted_context = format_context_as_text(limited_context_nodes)

      # Cache results if enabled
      if @cag_config[:enable_caching]
        @cache[cache_key] = formatted_context
        # Simple cache eviction - keep only last 100 entries
        if @cache.length > 100
          oldest_key = @cache.keys.first
          @cache.delete(oldest_key)
        end
      end

      Print.info "Retrieved context for query with #{limited_context_nodes.length} nodes"
      formatted_context
    rescue => e
      Print.err "Error getting context for query: #{e.message}"
      Print.err e.backtrace.inspect
      nil
    end
  end

  def add_knowledge_triplet(subject, relationship, object, properties = {})
    unless @initialized
      setup unless setup
      return false
    end

    Print.info "Adding knowledge triplet: #{subject} -- #{relationship} --> #{object}"

    begin
      # Create or get subject node
      subject_id = @knowledge_graph.create_id_from_text(subject, 'entity')
      subject_node = @knowledge_graph.find_nodes_by_property('name', subject, 1).first
      unless subject_node
        @knowledge_graph.create_node(subject_id, ['Entity'], { name: subject, type: 'unknown' })
      end

      # Create or get object node
      object_id = @knowledge_graph.create_id_from_text(object, 'entity')
      object_node = @knowledge_graph.find_nodes_by_property('name', object, 1).first
      unless object_node
        @knowledge_graph.create_node(object_id, ['Entity'], { name: object, type: 'unknown' })
      end

      # Create relationship
      success = @knowledge_graph.create_relationship(subject_id, object_id, relationship, properties)

      # Clear cache if enabled
      @cache.clear if @cag_config[:enable_caching]

      success
    rescue => e
      Print.err "Error adding knowledge triplet: #{e.message}"
      Print.err e.backtrace.inspect
      false
    end
  end

  def find_related_entities(entity_name, relationship_type = nil, depth = 1)
    unless @initialized
      setup unless setup
      return []
    end

    Print.info "Finding related entities for: #{entity_name}"

    begin
      # Find the entity node
      entity_id = @knowledge_graph.create_id_from_text(entity_name, 'entity')
      entity_nodes = @knowledge_graph.find_nodes_by_property('name', entity_name, 1)
      return [] if entity_nodes.empty?

      # Get context
      context = @knowledge_graph.get_node_context(entity_nodes.first[:id], depth, @cag_config[:max_context_nodes])
      context || []
    rescue => e
      Print.err "Error finding related entities: #{e.message}"
      Print.err e.backtrace.inspect
      []
    end
  end

  def create_knowledge_base_from_triplets(triplets, batch_size = 100)
    unless @initialized
      setup unless setup
      return false
    end

    Print.info "Creating knowledge base from #{triplets.length} triplets"

    begin
      # Process in batches
      triplets.each_slice(batch_size) do |batch|
        batch.each do |triplet|
          add_knowledge_triplet(
            triplet[:subject],
            triplet[:relationship],
            triplet[:object],
            triplet[:properties] || {}
          )
        end
      end

      Print.info "Successfully created knowledge base"
      true
    rescue => e
      Print.err "Error creating knowledge base: #{e.message}"
      Print.err e.backtrace.inspect
      false
    end
  end

  def test_connection
    Print.info "Testing CAG Manager connections..."

    knowledge_graph_ok = @knowledge_graph.test_connection

    overall_ok = knowledge_graph_ok

    Print.info "Knowledge Graph: #{knowledge_graph_ok ? 'OK' : 'FAILED'}"
    Print.info "CAG Manager: #{overall_ok ? 'OK' : 'FAILED'}"

    overall_ok
  end

  def cleanup
    Print.info "Cleaning up CAG Manager..."
    @knowledge_graph.disconnect if @knowledge_graph.respond_to?(:disconnect)
    @cache.clear if @cache
    @initialized = false
  end

  private

  def create_knowledge_graph(config)
    provider = config[:provider] || 'neo4j'

    case provider.downcase
    when 'neo4j'
      require './cag/neo4j_client.rb'
      Neo4jClient.new(config)
    when 'tigergraph'
      require './cag/tigergraph_client.rb'
      TigerGraphClient.new(config)
    when 'amazon_neptune'
      require './cag/amazon_neptune_client.rb'
      AmazonNeptuneClient.new(config)
    when 'arangodb'
      require './cag/arangodb_client.rb'
      ArangoDBCClient.new(config)
    when 'in_memory'
      require './cag/in_memory_graph_client.rb'
      InMemoryGraphClient.new(config)
    else
      raise ArgumentError, "Unsupported knowledge graph provider: #{provider}"
    end
  end

  def create_entity_extractor(config)
    provider = config[:provider] || 'rule_based'

    case provider.downcase
    when 'llm_based'
      require './cag/llm_entity_extractor.rb'
      LLMEntityExtractor.new(config)
    when 'spacy'
      require './cag/spacy_entity_extractor.rb'
      SpacyEntityExtractor.new(config)
    when 'rule_based'
      # Use built-in rule-based extraction
      nil
    else
      Print.err "Unknown entity extractor provider: #{provider}, using rule-based"
      nil
    end
  end

  def expand_entity_context(entity, max_depth, max_nodes, processed_nodes)
    context_nodes = []

    # Find nodes matching the entity
    matching_nodes = @knowledge_graph.find_nodes_by_property('name', entity[:value], 5)

    # If no direct matches found, map entity to cybersecurity concepts
    if matching_nodes.empty?
      mapped_concepts = map_entity_to_concepts(entity)
      mapped_concepts.each do |concept|
        concept_nodes = @knowledge_graph.find_nodes_by_property('name', concept, 3)
        matching_nodes.concat(concept_nodes)
      end
    end

    return context_nodes if matching_nodes.empty?

    matching_nodes.each do |node|
      next if processed_nodes.include?(node[:id])

      # Get node context
      node_context = @knowledge_graph.get_node_context(node[:id], max_depth, max_nodes)
      next unless node_context

      # Add to context
      context_nodes.concat(node_context)
      processed_nodes.add(node[:id])

      # Add nodes to processed set
      node_context.each { |context_node| processed_nodes.add(context_node[:id]) }
    end

    context_nodes
  end

  def format_context_as_text(nodes)
    return "" if nodes.nil? || nodes.empty?

    sections = {}

    # Group nodes by labels
    nodes.each do |node|
      labels = node[:labels] || node['labels'] || []
      main_label = labels.first || 'Unknown'

      sections[main_label] ||= []
      sections[main_label] << node
    end

    # Format each section
    context_parts = []
    sections.each do |label, section_nodes|
      context_parts << "=== #{label.pluralize.capitalize} ==="

      section_nodes.each_with_index do |node, index|
        properties = node[:properties] || node['properties'] || {}
        name = properties[:name] || properties['name'] || node[:id] || node['id']

        context_part = "• #{name}"

        # Add other relevant properties
        other_props = properties.reject { |k, v| k == 'name' }
        unless other_props.empty?
          prop_values = other_props.map { |k, v| "#{k}: #{v}" }.join(', ')
          context_part += " (#{prop_values})"
        end

        context_parts << context_part
      end
      context_parts << ""
    end

    context_parts.join("\n")
  end

  # Map extracted entities to relevant cybersecurity concepts
  def map_entity_to_concepts(entity)
    entity_type = entity[:type]
    entity_value = entity[:value].downcase

    mappings = {
      'ip_address' => [
        'Network Scanning', 'Reconnaissance', 'Command and Control',
        'Lateral Movement', 'Command-Line Interface'
      ],
      'url' => [
        'Malware Delivery', 'Phishing', 'Drive-by Compromise',
        'Exploit Public-Facing Application', 'Initial Access'
      ],
      'hash' => [
        'Malware Analysis', 'File Hashing', 'Forensic Analysis',
        'Malware', 'Trojan'
      ],
      'filename' => [
        'Malware', 'Trojan', 'Backdoor', 'Executable',
        'Malware Delivery', 'Initial Access'
      ],
      'port' => [
        'Network Scanning', 'Command and Control', 'Lateral Movement',
        'Reconnaissance', 'Command-Line Interface'
      ],
      'email' => [
        'Phishing', 'Spearphishing', 'Social Engineering',
        'Initial Access', 'Malware Delivery'
      ]
    }

    # Get base mappings for entity type
    concepts = mappings[entity_type] || []

    # Add specific mappings based on entity content
    case entity_type
    when 'url'
      if entity_value.include?('malicious') || entity_value.include?('evil')
        concepts << 'Malware' << 'Trojan'
      elsif entity_value.include?('phish')
        concepts << 'Phishing' << 'Social Engineering'
      end
    when 'filename'
      if entity_value.include?('malware') || entity_value.include?('trojan')
        concepts << 'Malware' << 'Trojan'
      elsif entity_value.include?('dll') || entity_value.include?('exe')
        concepts << 'Executable' << 'Malware'
      end
    when 'ip_address'
      # Internal IP addresses might suggest lateral movement
      if entity_value.start_with?('192.168.') || entity_value.start_with?('10.') || entity_value.start_with?('172.')
        concepts << 'Lateral Movement'
      end
    end

    # Remove duplicates and return
    concepts.uniq
  end
end

# Add string pluralization helper
class String
  def pluralize
    return self + "s" unless self.end_with?('y')
    self[0..-2] + "ies"
  end
end
