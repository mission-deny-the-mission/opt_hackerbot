require './knowledge_graph_interface.rb'
require './print.rb'
require 'json'
require 'fileutils'
require 'digest'

# Offline In-Memory Knowledge Graph Client with Persistent Storage
# This client operates entirely from local disk storage without requiring network connectivity
class InMemoryGraphOfflineClient < KnowledgeGraphInterface
  def initialize(config)
    super(config)
    @storage_path = config[:storage_path] || File.join(Dir.pwd, 'knowledge_bases', 'offline', 'graph')
    @persist_graph = config[:persist_graph] != false
    @load_from_file = config[:load_from_file] != false
    @auto_save_interval = config[:auto_save_interval] || 300  # 5 minutes
    @compression_enabled = config[:compression_enabled] != false
    @snapshot_enabled = config[:snapshot_enabled] != false
    @max_snapshots = config[:max_snapshots] || 10

    # Graph data structures
    @nodes = {}
    @relationships = []
    @node_index = {
      by_label: {},
      by_property: {},
      by_id: {}
    }
    @relationship_index = {
      by_type: {},
      by_from_node: {},
      by_to_node: {}
    }

    # Performance tracking
    @last_save_time = Time.now
    @operation_count = 0
    @auto_save_thread = nil
  end

  def connect
    Print.info "Connecting to offline knowledge graph at: #{@storage_path}"

    # Create storage directory if it doesn't exist
    FileUtils.mkdir_p(@storage_path) unless File.exist?(@storage_path)

    # Load existing data from disk
    if @load_from_file
      load_nodes_from_disk
      load_relationships_from_disk
      load_indexes_from_disk
      load_metadata_from_disk
    end

    # Start auto-save thread if configured
    start_auto_save_thread if @auto_save_interval > 0

    @initialized = true
    Print.info "Connected to offline knowledge graph successfully"

    # Print statistics
    Print.info "Loaded #{@nodes.length} nodes, #{@relationships.length} relationships"
    true
  rescue => e
    Print.err "Failed to connect to offline knowledge graph: #{e.message}"
    Print.err e.backtrace.inspect
    false
  end

  def disconnect
    Print.info "Disconnecting from offline knowledge graph"

    # Stop auto-save thread
    stop_auto_save_thread

    # Save all data to disk before disconnecting
    if @persist_graph
      save_nodes_to_disk
      save_relationships_to_disk
      save_indexes_to_disk
      save_metadata_to_disk

      # Create final snapshot
      create_snapshot if @snapshot_enabled
    end

    @nodes.clear
    @relationships.clear
    @node_index.each_value(&:clear)
    @relationship_index.each_value(&:clear)
    @initialized = false

    Print.info "Offline knowledge graph disconnected and data saved"
    true
  end

  def create_node(node_id, labels, properties = {})
    validate_node_id(node_id)
    validate_labels(labels)
    validate_properties(properties)

    Print.info "Creating offline node: #{node_id} with labels #{labels}"

    begin
      # Check if node already exists
      if @nodes.key?(node_id)
        Print.debug "Node #{node_id} already exists, updating instead"
        return update_node(node_id, labels, properties)
      end

      # Create node with timestamp
      node = {
        id: node_id,
        labels: labels,
        properties: properties,
        created_at: Time.now,
        updated_at: Time.now,
        version: 1
      }

      @nodes[node_id] = node

      # Update indexes
      update_node_indexes(node, :create)

      # Increment operation count
      @operation_count += 1

      # Auto-save if needed
      auto_save_if_needed

      Print.info "Successfully created offline node: #{node_id}"
      node
    rescue => e
      Print.err "Failed to create offline node #{node_id}: #{e.message}"
      Print.err e.backtrace.inspect
      nil
    end
  end

  def create_relationship(from_node_id, to_node_id, relationship_type, properties = {})
    validate_node_id(from_node_id)
    validate_node_id(to_node_id)
    validate_relationship_type(relationship_type)
    validate_properties(properties)

    Print.info "Creating offline relationship: #{from_node_id} -- #{relationship_type} --> #{to_node_id}"

    begin
      # Check if nodes exist
      unless @nodes.key?(from_node_id)
        Print.err "Source node #{from_node_id} does not exist"
        return nil
      end

      unless @nodes.key?(to_node_id)
        Print.err "Target node #{to_node_id} does not exist"
        return nil
      end

      # Generate unique relationship ID
      relationship_id = generate_relationship_id(from_node_id, to_node_id, relationship_type)

      # Check if relationship already exists
      existing_relationship = find_relationship_by_nodes(from_node_id, to_node_id, relationship_type)
      if existing_relationship
        Print.debug "Relationship already exists, updating instead"
        return update_relationship(existing_relationship[:id], properties)
      end

      # Create relationship
      relationship = {
        id: relationship_id,
        from_node_id: from_node_id,
        to_node_id: to_node_id,
        type: relationship_type,
        properties: properties,
        created_at: Time.now,
        updated_at: Time.now,
        version: 1
      }

      @relationships << relationship

      # Update indexes
      update_relationship_indexes(relationship, :create)

      # Increment operation count
      @operation_count += 1

      # Auto-save if needed
      auto_save_if_needed

      Print.info "Successfully created offline relationship: #{relationship_id}"
      relationship
    rescue => e
      Print.err "Failed to create offline relationship: #{e.message}"
      Print.err e.backtrace.inspect
      nil
    end
  end

  def find_nodes_by_label(label, limit = 10)
    raise ArgumentError, "Label cannot be empty" if label.to_s.strip.empty?

    Print.info "Finding offline nodes by label: #{label}"

    begin
      nodes = @node_index[:by_label][label.downcase] || []
      limited_nodes = nodes.take(limit)

      Print.info "Found #{limited_nodes.length} offline nodes with label #{label}"
      limited_nodes
    rescue => e
      Print.err "Failed to find offline nodes by label #{label}: #{e.message}"
      []
    end
  end

  def find_nodes_by_property(property_name, property_value, limit = 10)
    raise ArgumentError, "Property name cannot be empty" if property_name.to_s.strip.empty?

    Print.info "Finding offline nodes by property: #{property_name}=#{property_value}"

    begin
      key = "#{property_name.downcase}:#{property_value.to_s}"
      nodes = @node_index[:by_property][key] || []
      limited_nodes = nodes.take(limit)

      Print.info "Found #{limited_nodes.length} offline nodes with property #{property_name}=#{property_value}"
      limited_nodes
    rescue => e
      Print.err "Failed to find offline nodes by property #{property_name}: #{e.message}"
      []
    end
  end

  def find_relationships(node_id, relationship_type = nil, direction = nil)
    validate_node_id(node_id)

    Print.info "Finding offline relationships for node: #{node_id}"

    begin
      relationships = []

      if direction.nil? || direction == :outgoing || direction == 'outgoing'
        # Find outgoing relationships
        outgoing_rels = @relationship_index[:by_from_node][node_id] || []
        if relationship_type
          outgoing_rels = outgoing_rels.select { |r| r[:type].downcase == relationship_type.downcase }
        end
        relationships.concat(outgoing_rels)
      end

      if direction.nil? || direction == :incoming || direction == 'incoming'
        # Find incoming relationships
        incoming_rels = @relationship_index[:by_to_node][node_id] || []
        if relationship_type
          incoming_rels = incoming_rels.select { |r| r[:type].downcase == relationship_type.downcase }
        end
        relationships.concat(incoming_rels)
      end

      Print.info "Found #{relationships.length} offline relationships for node #{node_id}"
      relationships
    rescue => e
      Print.err "Failed to find offline relationships for node #{node_id}: #{e.message}"
      []
    end
  end

  def search_nodes(search_query, limit = 10)
    normalized_query = normalize_search_query(search_query)
    return [] if normalized_query.empty?

    Print.info "Searching offline nodes with query: #{search_query}"

    begin
      matching_nodes = []
      query_terms = normalized_query.split

      # Search in node ID, labels, and properties
      @nodes.values.each do |node|
        score = calculate_node_relevance_score(node, query_terms)
        if score > 0
          matching_nodes << { node: node, score: score }
        end
      end

      # Sort by relevance score and limit results
      sorted_results = matching_nodes.sort_by { |result| -result[:score] }
      limited_results = sorted_results.take(limit).map { |result| result[:node] }

      Print.info "Found #{limited_results.length} offline nodes matching query '#{search_query}'"
      limited_results
    rescue => e
      Print.err "Failed to search offline nodes: #{e.message}"
      []
    end
  end

  def get_node_context(node_id, max_depth = 2, max_nodes = 20)
    validate_node_id(node_id)

    unless @nodes.key?(node_id)
      Print.err "Offline node #{node_id} does not exist"
      return nil
    end

    Print.info "Getting context for offline node: #{node_id} (depth: #{max_depth}, max_nodes: #{max_nodes})"

    begin
      context_nodes = []
      visited_nodes = Set.new([node_id])
      nodes_at_level = [node_id]
      current_depth = 0

      while current_depth < max_depth && !nodes_at_level.empty? && context_nodes.length < max_nodes
        next_level_nodes = []

        nodes_at_level.each do |current_node_id|
          # Get all relationships for this node
          relationships = find_relationships(current_node_id)

          relationships.each do |rel|
            related_node_id = rel[:from_node_id] == current_node_id ? rel[:to_node_id] : rel[:from_node_id]

            unless visited_nodes.include?(related_node_id)
              if @nodes.key?(related_node_id)
                related_node = @nodes[related_node_id]
                context_node = related_node.dup
                context_node[:relationship_type] = rel[:type]
                context_node[:relationship_direction] = rel[:from_node_id] == current_node_id ? :outgoing : :incoming
                context_node[:relationship_properties] = rel[:properties]
                context_node[:depth] = current_depth + 1
                context_node[:distance_score] = calculate_distance_score(current_depth, rel)

                context_nodes << context_node
                visited_nodes.add(related_node_id)
                next_level_nodes << related_node_id

                break if context_nodes.length >= max_nodes
              end
            end
          end

          break if context_nodes.length >= max_nodes
        end

        nodes_at_level = next_level_nodes
        current_depth += 1
      end

      Print.info "Retrieved context for offline node #{node_id} with #{context_nodes.length} nodes"
      context_nodes
    rescue => e
      Print.err "Failed to get node context for offline node #{node_id}: #{e.message}"
      Print.err e.backtrace.inspect
      nil
    end
  end

  def delete_node(node_id)
    validate_node_id(node_id)

    Print.info "Deleting offline node: #{node_id}"

    begin
      unless @nodes.key?(node_id)
        Print.debug "Offline node #{node_id} does not exist"
        return true
      end

      node = @nodes[node_id]

      # Remove all relationships involving this node
      @relationships.reject! { |rel|
        rel[:from_node_id] == node_id || rel[:to_node_id] == node_id
      }

      # Remove from indexes
      update_node_indexes(node, :delete)

      # Remove node
      @nodes.delete(node_id)

      # Rebuild relationship indexes (simpler than precise removal)
      rebuild_relationship_indexes

      # Increment operation count
      @operation_count += 1

      # Auto-save if needed
      auto_save_if_needed

      Print.info "Successfully deleted offline node: #{node_id}"
      true
    rescue => e
      Print.err "Failed to delete offline node #{node_id}: #{e.message}"
      false
    end
  end

  def test_connection
    Print.info "Testing offline knowledge graph connection"

    if @initialized
      # Test that we can read/write to storage directory
      test_file = File.join(@storage_path, '.connection_test')
      begin
        File.write(test_file, "test_#{Time.now.to_i}")
        File.read(test_file)
        File.delete(test_file)

        Print.info "Offline knowledge graph connection test successful"
        true
      rescue => e
        Print.err "Offline knowledge graph storage test failed: #{e.message}"
        false
      end
    else
      Print.err "Offline knowledge graph not initialized"
      false
    end
  end

  def get_graph_stats
    {
      node_count: @nodes.length,
      relationship_count: @relationships.length,
      labels_count: @node_index[:by_label].keys.length,
      initialized: @initialized,
      storage_path: @storage_path,
      operation_count: @operation_count,
      last_save_time: @last_save_time,
      auto_save_enabled: @auto_save_thread&.alive?,
      compression_enabled: @compression_enabled,
      snapshot_enabled: @snapshot_enabled
    }
  end

  def export_graph(export_path, format = 'json')
    Print.info "Exporting offline knowledge graph to: #{export_path} (format: #{format})"

    begin
      export_data = {
        nodes: @nodes.values,
        relationships: @relationships,
        metadata: {
          exported_at: Time.now.iso8601,
          node_count: @nodes.length,
          relationship_count: @relationships.length,
          version: "1.0",
          format: format
        }
      }

      case format.downcase
      when 'json'
        if @compression_enabled
          require 'zlib'
          File.open(export_path, 'wb') do |file|
            compressed_data = Zlib.deflate(JSON.pretty_generate(export_data))
            file.write(compressed_data)
          end
        else
          File.write(export_path, JSON.pretty_generate(export_data))
        end
      when 'graphml'
        export_to_graphml(export_path, export_data)
      else
        raise ArgumentError, "Unsupported export format: #{format}"
      end

      Print.info "Successfully exported offline knowledge graph to: #{export_path}"
      true
    rescue => e
      Print.err "Failed to export offline knowledge graph: #{e.message}"
      false
    end
  end

  def import_graph(import_path, format = 'json')
    unless File.exist?(import_path)
      Print.err "Import file not found: #{import_path}"
      return false
    end

    Print.info "Importing offline knowledge graph from: #{import_path} (format: #{format})"

    begin
      case format.downcase
      when 'json'
        if import_path.end_with?('.gz') || @compression_enabled
          require 'zlib'
          compressed_data = File.binread(import_path)
          json_data = Zlib.inflate(compressed_data)
          import_data = JSON.parse(json_data)
        else
          import_data = JSON.parse(File.read(import_path))
        end
      when 'graphml'
        import_data = import_from_graphml(import_path)
      else
        raise ArgumentError, "Unsupported import format: #{format}"
      end

      # Validate import data
      if import_data['nodes'] && import_data['relationships']
        # Clear existing data
        @nodes.clear
        @relationships.clear
        @node_index.each_value(&:clear)
        @relationship_index.each_value(&:clear)

        # Import nodes
        import_data['nodes'].each do |node_data|
          create_node(node_data['id'], node_data['labels'], node_data['properties'])
        end

        # Import relationships
        import_data['relationships'].each do |rel_data|
          create_relationship(rel_data['from_node_id'], rel_data['to_node_id'], rel_data['type'], rel_data['properties'])
        end

        # Rebuild indexes
        rebuild_all_indexes

        # Save imported data
        if @persist_graph
          save_all_to_disk
          create_snapshot if @snapshot_enabled
        end

        Print.info "Successfully imported offline knowledge graph"
        true
      else
        Print.err "Invalid import data format"
        false
      end
    rescue => e
      Print.err "Failed to import offline knowledge graph: #{e.message}"
      Print.err e.backtrace.inspect
      false
    end
  end

  def create_snapshot
    return unless @snapshot_enabled

    Print.info "Creating offline knowledge graph snapshot..."

    begin
      timestamp = Time.now.strftime('%Y%m%d_%H%M%S')
      snapshot_path = File.join(@storage_path, 'snapshots', "snapshot_#{timestamp}")

      # Create snapshot directory
      FileUtils.mkdir_p(snapshot_path) unless File.exist?(snapshot_path)

      # Export current state
      export_path = File.join(snapshot_path, "graph_export.json.gz")
      export_graph(export_path, 'json')

      # Create metadata file
      metadata = {
        snapshot_time: Time.now.iso8601,
        node_count: @nodes.length,
        relationship_count: @relationships.length,
        operation_count: @operation_count,
        version: "1.0"
      }

      metadata_path = File.join(snapshot_path, "metadata.json")
      File.write(metadata_path, JSON.pretty_generate(metadata))

      # Clean up old snapshots
      cleanup_old_snapshots

      Print.info "Snapshot created successfully: #{snapshot_path}"
      true
    rescue => e
      Print.err "Failed to create snapshot: #{e.message}"
      false
    end
  end

  def restore_snapshot(snapshot_timestamp)
    snapshot_path = File.join(@storage_path, 'snapshots', "snapshot_#{snapshot_timestamp}")
    export_path = File.join(snapshot_path, "graph_export.json.gz")

    unless File.exist?(export_path)
      Print.err "Snapshot not found: #{snapshot_path}"
      return false
    end

    Print.info "Restoring offline knowledge graph from snapshot: #{snapshot_timestamp}"

    # Import the snapshot
    import_graph(export_path, 'json')
  end

  def list_snapshots
    snapshot_dir = File.join(@storage_path, 'snapshots')
    return [] unless File.exist?(snapshot_dir)

    snapshots = []
    Dir.glob(File.join(snapshot_dir, 'snapshot_*')).each do |snapshot_path|
      metadata_path = File.join(snapshot_path, 'metadata.json')
      if File.exist?(metadata_path)
        begin
          metadata = JSON.parse(File.read(metadata_path))
          snapshots << {
            timestamp: File.basename(snapshot_path).sub('snapshot_', ''),
            path: snapshot_path,
            metadata: metadata
          }
        rescue => e
          Print.debug "Failed to read snapshot metadata: #{snapshot_path}"
        end
      end
    end

    snapshots.sort_by { |s| s[:timestamp] }.reverse
  end

  private

  def nodes_path
    File.join(@storage_path, 'nodes.json')
  end

  def relationships_path
    File.join(@storage_path, 'relationships.bin')
  end

  def indexes_path
    File.join(@storage_path, 'indexes.json')
  end

  def metadata_path
    File.join(@storage_path, 'metadata.json')
  end

  def load_nodes_from_disk
    nodes_file = nodes_path
    return unless File.exist?(nodes_file)

    begin
      nodes_data = JSON.parse(File.read(nodes_file))
      @nodes = nodes_data['nodes'].transform_values { |node|
        # Convert string timestamps back to Time objects
        node['created_at'] = Time.parse(node['created_at']) if node['created_at'].is_a?(String)
        node['updated_at'] = Time.parse(node['updated_at']) if node['updated_at'].is_a?(String)
        node
      }
      Print.debug "Loaded #{@nodes.length} nodes from disk"
    rescue => e
      Print.err "Failed to load nodes from disk: #{e.message}"
    end
  end

  def save_nodes_to_disk
    nodes_file = nodes_path
    nodes_data = {
      nodes: @nodes,
      saved_at: Time.now.iso8601,
      node_count: @nodes.length,
      version: "1.0"
    }

    begin
      FileUtils.mkdir_p(File.dirname(nodes_file)) unless File.exist?(File.dirname(nodes_file))
      File.write(nodes_file, JSON.pretty_generate(nodes_data))
      Print.debug "Saved #{@nodes.length} nodes to disk"
    rescue => e
      Print.err "Failed to save nodes to disk: #{e.message}"
    end
  end

  def load_relationships_from_disk
    relationships_file = relationships_path
    return unless File.exist?(relationships_file)

    begin
      # Read binary data
      binary_data = File.binread(relationships_file)

      # Deserialize data
      require 'stringio'
      require 'marshal'

      io = StringIO.new(binary_data)
      @relationships = Marshal.load(io)

      Print.debug "Loaded #{@relationships.length} relationships from disk"
    rescue => e
      Print.err "Failed to load relationships from disk: #{e.message}"
    end
  end

  def save_relationships_to_disk
    relationships_file = relationships_path

    begin
      FileUtils.mkdir_p(File.dirname(relationships_file)) unless File.exist?(File.dirname(relationships_file))

      # Serialize using Marshal for binary efficiency
      require 'stringio'
      require 'marshal'

      io = StringIO.new
      Marshal.dump(@relationships, io)
      binary_data = io.string

      File.binwrite(relationships_file, binary_data)
      Print.debug "Saved #{@relationships.length} relationships to disk"
    rescue => e
      Print.err "Failed to save relationships to disk: #{e.message}"
    end
  end

  def load_indexes_from_disk
    indexes_file = indexes_path
    return unless File.exist?(indexes_file)

    begin
      indexes_data = JSON.parse(File.read(indexes_file))
      @node_index = indexes_data['node_index'] || {}
      @relationship_index = indexes_data['relationship_index'] || {}
      Print.debug "Loaded indexes from disk"
    rescue => e
      Print.err "Failed to load indexes from disk: #{e.message}"
    end
  end

  def save_indexes_to_disk
    indexes_file = indexes_path
    indexes_data = {
      node_index: @node_index,
      relationship_index: @relationship_index,
      saved_at: Time.now.iso8601,
      version: "1.0"
    }

    begin
      FileUtils.mkdir_p(File.dirname(indexes_file)) unless File.exist?(File.dirname(indexes_file))
      File.write(indexes_file, JSON.pretty_generate(indexes_data))
      Print.debug "Saved indexes to disk"
    rescue => e
      Print.err "Failed to save indexes to disk: #{e.message}"
    end
  end

  def load_metadata_from_disk
    metadata_file = metadata_path
    return unless File.exist?(metadata_file)

    begin
      metadata_data = JSON.parse(File.read(metadata_file))
      @operation_count = metadata_data['operation_count'] || 0
      @last_save_time = Time.parse(metadata_data['last_save_time']) if metadata_data['last_save_time']
      Print.debug "Loaded metadata from disk"
    rescue => e
      Print.err "Failed to load metadata from disk: #{e.message}"
    end
  end

  def save_metadata_to_disk
    metadata_file = metadata_path
    metadata_data = {
      operation_count: @operation_count,
      last_save_time: Time.now.iso8601,
      node_count: @nodes.length,
      relationship_count: @relationships.length,
      version: "1.0"
    }

    begin
      FileUtils.mkdir_p(File.dirname(metadata_file)) unless File.exist?(File.dirname(metadata_file))
      File.write(metadata_file, JSON.pretty_generate(metadata_data))
      Print.debug "Saved metadata to disk"
    rescue => e
      Print.err "Failed to save metadata to disk: #{e.message}"
    end
  end

  def save_all_to_disk
    save_nodes_to_disk
    save_relationships_to_disk
    save_indexes_to_disk
    save_metadata_to_disk
    @last_save_time = Time.now
  end

  def update_node_indexes(node, operation)
    case operation
    when :create
      # Index by labels
      node[:labels].each do |label|
        @node_index[:by_label][label.downcase] ||= []
        @node_index[:by_label][label.downcase] << node
      end

      # Index by properties
      node[:properties].each do |key, value|
        index_key = "#{key.downcase}:#{value.to_s}"
        @node_index[:by_property][index_key] ||= []
        @node_index[:by_property][index_key] << node
      end

      # Index by ID
      @node_index[:by_id][node[:id]] = node

    when :delete
      # Remove from label indexes
      node[:labels].each do |label|
        if @node_index[:by_label][label.downcase]
          @node_index[:by_label][label.downcase].delete(node)
          @node_index[:by_label].delete(label.downcase) if @node_index[:by_label][label.downcase].empty?
        end
      end

      # Remove from property indexes
      node[:properties].each do |key, value|
        index_key = "#{key.downcase}:#{value.to_s}"
        if @node_index[:by_property][index_key]
          @node_index[:by_property][index_key].delete(node)
          @node_index[:by_property].delete(index_key) if @node_index[:by_property][index_key].empty?
        end
      end

      # Remove from ID index
      @node_index[:by_id].delete(node[:id])
    end
  end

  def update_relationship_indexes(relationship, operation)
    case operation
    when :create
      # Index by type
      @relationship_index[:by_type][relationship[:type].downcase] ||= []
      @relationship_index[:by_type][relationship[:type].downcase] << relationship

      # Index by from node
      @relationship_index[:by_from_node][relationship[:from_node_id]] ||= []
      @relationship_index[:by_from_node][relationship[:from_node_id]] << relationship

      # Index by to node
      @relationship_index[:by_to_node][relationship[:to_node_id]] ||= []
      @relationship_index[:by_to_node][relationship[:to_node_id]] << relationship
    end
  end

  def rebuild_relationship_indexes
    @relationship_index[:by_type].clear
    @relationship_index[:by_from_node].clear
    @relationship_index[:by_to_node].clear

    @relationships.each do |rel|
      update_relationship_indexes(rel, :create)
    end
  end

  def rebuild_all_indexes
    @node_index[:by_label].clear
    @node_index[:by_property].clear
    @node_index[:by_id].clear
    @relationship_index[:by_type].clear
    @relationship_index[:by_from_node].clear
    @relationship_index[:by_to_node].clear

    @nodes.values.each do |node|
      update_node_indexes(node, :create)
    end

    @relationships.each do |rel|
      update_relationship_indexes(rel, :create)
    end
  end

  def generate_relationship_id(from_node_id, to_node_id, relationship_type)
    # Generate consistent relationship ID
    key = "#{from_node_id}_#{to_node_id}_#{relationship_type}"
    Digest::MD5.hexdigest(key)
  end

  def find_relationship_by_nodes(from_node_id, to_node_id, relationship_type)
    @relationships.find do |rel|
      rel[:from_node_id] == from_node_id &&
      rel[:to_node_id] == to_node_id &&
      rel[:type].downcase == relationship_type.downcase
    end
  end

  def update_node(node_id, labels, properties)
    node = @nodes[node_id]

    # Remove old indexes
    update_node_indexes(node, :delete)

    # Update node
    node[:labels] = labels
    node[:properties] = properties
    node[:updated_at] = Time.now
    node[:version] += 1

    # Add new indexes
    update_node_indexes(node, :create)

    node
  end

  def update_relationship(relationship_id, properties)
    relationship = @relationships.find { |rel| rel[:id] == relationship_id }
    return nil unless relationship

    relationship[:properties] = properties
    relationship[:updated_at] = Time.now
    relationship[:version] += 1

    relationship
  end

  def calculate_node_relevance_score(node, query_terms)
    score = 0

    # Score based on node ID match
    node_id_text = node[:id].to_s.downcase
    score += query_terms.sum { |term| node_id_text.include?(term) ? 2 : 0 }

    # Score based on labels match
    labels_text = node[:labels].join(' ').downcase
    score += query_terms.sum { |term| labels_text.include?(term) ? 3 : 0 }

    # Score based on properties match
    properties_text = node[:properties].map { |k, v| "#{k} #{v}" }.join(' ').downcase
    score += query_terms.sum { |term| properties_text.include?(term) ? 1 : 0 }

    score
  end

  def calculate_distance_score(depth, relationship)
    # Higher score for closer nodes and more important relationships
    distance_score = 1.0 / (depth + 1)

    # Boost score for important relationships
    importance_boost = case relationship[:type].downcase
                        when 'related_to', 'similar_to' then 0.1
                        when 'part_of', 'contains' then 0.2
                        when 'causes', 'enables' then 0.3
                        else 0.0
                        end

    distance_score + importance_boost
  end

  def start_auto_save_thread
    return unless @auto_save_interval > 0

    @auto_save_thread = Thread.new do
      loop do
        sleep @auto_save_interval
        if @initialized && @persist_graph
          Print.debug "Auto-saving offline knowledge graph..."
          save_all_to_disk
        end
      end
    end

    Print.info "Auto-save thread started (interval: #{@auto_save_interval}s)"
  end

  def stop_auto_save_thread
    return unless @auto_save_thread

    @auto_save_thread.kill
    @auto_save_thread = nil
    Print.info "Auto-save thread stopped"
  end

  def auto_save_if_needed
    return unless @persist_graph && @auto_save_interval > 0

    # Auto-save if operation count exceeds threshold or time since last save is too long
    if @operation_count >= 100 || (Time.now - @last_save_time) >= @auto_save_interval
      save_all_to_disk
      @operation_count = 0
    end
  end

  def cleanup_old_snapshots
    return unless @snapshot_enabled

    snapshot_dir = File.join(@storage_path, 'snapshots')
    return unless File.exist?(snapshot_dir)

    snapshots = Dir.glob(File.join(snapshot_dir, 'snapshot_*')).sort_by { |f| File.mtime(f) }

    # Remove oldest snapshots if we exceed the maximum
    while snapshots.length > @max_snapshots
      oldest_snapshot = snapshots.shift
      FileUtils.rm_rf(oldest_snapshot)
      Print.debug "Removed old snapshot: #{oldest_snapshot}"
    end
  end

  def export_to_graphml(export_path, export_data)
    # Export to GraphML format for compatibility with graph visualization tools
    graphml_content = <<~GRAPHML
      <?xml version="1.0" encoding="UTF-8"?>
      <graphml xmlns="http://graphml.graphdrawing.org/xmlns"
               xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
               xsi:schemaLocation="http://graphml.graphdrawing.org/xmlns
               http://graphml.graphdrawing.org/xmlns/1.0/graphml.xsd">
        <key id="label" for="node" attr.name="label" attr.type="string"/>
        <key id="properties" for="node" attr.name="properties" attr.type="string"/>
        <key id="type" for="edge" attr.name="type" attr.type="string"/>
        <key id="properties" for="edge" attr.name="properties" attr.type="string"/>
        <graph id="G" edgedefault="directed">
    GRAPHML

    # Add nodes
    export_data['nodes'].each do |node|
      labels_escaped = node['labels'].join(',').gsub('&', '&amp;').gsub('<', '&lt;').gsub('>', '&gt;')
      properties_escaped = node['properties'].to_json.gsub('&', '&amp;').gsub('<', '&lt;').gsub('>', '&gt;')

      graphml_content << <<~NODE
        <node id="#{node['id']}">
          <data key="label">#{labels_escaped}</data>
          <data key="properties">#{properties_escaped}</data>
        </node>
      NODE
    end

    # Add edges (relationships)
    export_data['relationships'].each do |rel|
      type_escaped = rel['type'].gsub('&', '&amp;').gsub('<', '&lt;').gsub('>', '&gt;')
      properties_escaped = rel['properties'].to_json.gsub('&', '&amp;').gsub('<', '&lt;').gsub('>', '&gt;')

      graphml_content << <<~EDGE
        <edge source="#{rel['from_node_id']}" target="#{rel['to_node_id']}">
          <data key="type">#{type_escaped}</data>
          <data key="properties">#{properties_escaped}</data>
        </edge>
      EDGE
    end

    graphml_content << <<~GRAPHML_TAIL
        </graph>
      </graphml>
    GRAPHML_TAIL

    File.write(export_path, graphml_content)
  end

  def import_from_graphml(import_path)
    # Basic GraphML import implementation
    # This is a simplified version - full implementation would require proper XML parsing
    require 'rexml/document'

    File.open(import_path) do |file|
      doc = REXML::Document.new(file)

      nodes = []
      relationships = []

      # Parse nodes
      doc.elements.each('//graphml/graph/node') do |node_elem|
        node_id = node_elem.attributes['id']
        label = node_elem.elements['data[@key="label"]']&.text || ''
        properties = node_elem.elements['data[@key="properties"]']&.text

        node = {
          'id' => node_id,
          'labels' => label.split(',').map(&:strip),
          'properties' => properties ? JSON.parse(properties) : {}
        }
        nodes << node
      end

      # Parse edges (relationships)
      doc.elements.each('//graphml/graph/edge') do |edge_elem|
        from_node = edge_elem.attributes['source']
        to_node = edge_elem.attributes['target']
        rel_type = edge_elem.elements['data[@key="type"]']&.text || 'RELATED_TO'
        properties = edge_elem.elements['data[@key="properties"]']&.text

        relationship = {
          'from_node_id' => from_node,
          'to_node_id' => to_node,
          'type' => rel_type,
          'properties' => properties ? JSON.parse(properties) : {}
        }
        relationships << relationship
      end

      {
        'nodes' => nodes,
        'relationships' => relationships,
        'metadata' => {
          'imported_at' => Time.now.iso8601,
          'format' => 'graphml'
        }
      }
    end
  end
end
