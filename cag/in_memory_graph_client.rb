require './knowledge_graph_interface.rb'
require './print.rb'

# In-memory knowledge graph client implementation for testing and local use
class InMemoryGraphClient < KnowledgeGraphInterface
  def initialize(config)
    super(config)
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
  end

  def connect
    Print.info "Connecting to in-memory knowledge graph..."

    # Initialize empty data structures
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

    @initialized = true
    Print.info "Connected to in-memory knowledge graph"
    true
  rescue => e
    Print.err "Failed to connect to in-memory knowledge graph: #{e.message}"
    false
  end

  def disconnect
    Print.info "Disconnecting from in-memory knowledge graph"
    @nodes.clear
    @relationships.clear
    @node_index.each do |key, index|
      index.clear
    end
    @relationship_index.each do |key, index|
      index.clear
    end
    @initialized = false
    true
  end

  def create_node(node_id, labels, properties = {})
    validate_node_id(node_id)
    validate_labels(labels)
    validate_properties(properties)

    Print.info "Creating node: #{node_id} with labels #{labels}"

    begin
      # Check if node already exists
      if @nodes.key?(node_id)
        Print.debug "Node #{node_id} already exists, updating instead"
        return update_node(node_id, labels, properties)
      end

      # Create node
      node = {
        id: node_id,
        labels: labels,
        properties: properties,
        created_at: Time.now,
        updated_at: Time.now
      }

      @nodes[node_id] = node

      # Update indexes
      update_node_indexes(node, :create)

      Print.info "Successfully created node: #{node_id}"
      node
    rescue => e
      Print.err "Failed to create node #{node_id}: #{e.message}"
      Print.err e.backtrace.inspect
      nil
    end
  end

  def create_relationship(from_node_id, to_node_id, relationship_type, properties = {})
    validate_node_id(from_node_id)
    validate_node_id(to_node_id)
    validate_relationship_type(relationship_type)
    validate_properties(properties)

    Print.info "Creating relationship: #{from_node_id} -- #{relationship_type} --> #{to_node_id}"

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

      # Create relationship
      relationship = {
        id: "rel_#{from_node_id}_#{to_node_id}_#{Time.now.to_i}",
        from_node_id: from_node_id,
        to_node_id: to_node_id,
        type: relationship_type,
        properties: properties,
        created_at: Time.now
      }

      @relationships << relationship

      # Update indexes
      update_relationship_indexes(relationship, :create)

      Print.info "Successfully created relationship: #{relationship[:id]}"
      relationship
    rescue => e
      Print.err "Failed to create relationship: #{e.message}"
      Print.err e.backtrace.inspect
      nil
    end
  end

  def find_nodes_by_label(label, limit = 10)
    raise ArgumentError, "Label cannot be empty" if label.to_s.strip.empty?

    Print.info "Finding nodes by label: #{label}"

    begin
      nodes = @node_index[:by_label][label.to_s.downcase] || []
      limited_nodes = nodes.take(limit)

      Print.info "Found #{limited_nodes.length} nodes with label #{label}"
      limited_nodes
    rescue => e
      Print.err "Failed to find nodes by label #{label}: #{e.message}"
      []
    end
  end

  def find_nodes_by_property(property_name, property_value, limit = 10)
    raise ArgumentError, "Property name cannot be empty" if property_name.to_s.strip.empty?

    Print.info "Finding nodes by property: #{property_name}=#{property_value}"

    begin
      key = "#{property_name.to_s.downcase}:#{property_value.to_s}"
      nodes = @node_index[:by_property][key] || []
      limited_nodes = nodes.take(limit)

      Print.info "Found #{limited_nodes.length} nodes with property #{property_name}=#{property_value}"
      limited_nodes
    rescue => e
      Print.err "Failed to find nodes by property #{property_name}: #{e.message}"
      []
    end
  end

  def find_relationships(node_id, relationship_type = nil, direction = nil)
    validate_node_id(node_id)

    Print.info "Finding relationships for node: #{node_id}"

    begin
      relationships = []

      if direction.nil? || direction == :outgoing || direction == 'outgoing'
        # Find outgoing relationships
        outgoing_rels = @relationship_index[:by_from_node][node_id] || []
        if relationship_type
          outgoing_rels = outgoing_rels.select { |r| r[:type].to_s.downcase == relationship_type.to_s.downcase }
        end
        relationships.concat(outgoing_rels)
      end

      if direction.nil? || direction == :incoming || direction == 'incoming'
        # Find incoming relationships
        incoming_rels = @relationship_index[:by_to_node][node_id] || []
        if relationship_type
          incoming_rels = incoming_rels.select { |r| r[:type].to_s.downcase == relationship_type.to_s.downcase }
        end
        relationships.concat(incoming_rels)
      end

      Print.info "Found #{relationships.length} relationships for node #{node_id}"
      relationships
    rescue => e
      Print.err "Failed to find relationships for node #{node_id}: #{e.message}"
      []
    end
  end

  def search_nodes(search_query, limit = 10)
    normalized_query = normalize_search_query(search_query)
    return [] if normalized_query.empty?

    Print.info "Searching nodes with query: #{search_query}"

    begin
      matching_nodes = []

      @nodes.values.each do |node|
        # Search in node ID
        if node[:id].to_s.downcase.include?(normalized_query)
          matching_nodes << node
          next
        end

        # Search in labels
        if node[:labels].any? { |label| label.to_s.downcase.include?(normalized_query) }
          matching_nodes << node
          next
        end

        # Search in properties
        node[:properties].each do |key, value|
          if key.to_s.downcase.include?(normalized_query) || value.to_s.downcase.include?(normalized_query)
            matching_nodes << node
            break
          end
        end
      end

      limited_nodes = matching_nodes.take(limit)
      Print.info "Found #{limited_nodes.length} nodes matching query '#{search_query}'"
      limited_nodes
    rescue => e
      Print.err "Failed to search nodes: #{e.message}"
      []
    end
  end

  def get_node_context(node_id, max_depth = 2, max_nodes = 20)
    validate_node_id(node_id)

    unless @nodes.key?(node_id)
      Print.err "Node #{node_id} does not exist"
      return nil
    end

    Print.info "Getting context for node: #{node_id} (depth: #{max_depth}, max_nodes: #{max_nodes})"

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

      Print.info "Retrieved context for node #{node_id} with #{context_nodes.length} nodes"
      context_nodes
    rescue => e
      Print.err "Failed to get node context for #{node_id}: #{e.message}"
      Print.err e.backtrace.inspect
      nil
    end
  end

  def delete_node(node_id)
    validate_node_id(node_id)

    Print.info "Deleting node: #{node_id}"

    begin
      unless @nodes.key?(node_id)
        Print.debug "Node #{node_id} does not exist"
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

      Print.info "Successfully deleted node: #{node_id}"
      true
    rescue => e
      Print.err "Failed to delete node #{node_id}: #{e.message}"
      false
    end
  end

  def test_connection
    Print.info "Testing in-memory knowledge graph connection"

    if @initialized
      Print.info "In-memory knowledge graph connection test successful"
      true
    else
      Print.err "In-memory knowledge graph not initialized"
      false
    end
  end

  def get_graph_stats
    {
      node_count: @nodes.length,
      relationship_count: @relationships.length,
      labels_count: @node_index[:by_label].keys.length,
      initialized: @initialized
    }
  end

  private

  def update_node_indexes(node, operation)
    case operation
    when :create
      # Index by labels
      node[:labels].each do |label|
        @node_index[:by_label][label.to_s.downcase] ||= []
        @node_index[:by_label][label.to_s.downcase] << node
      end

      # Index by properties
      node[:properties].each do |key, value|
        index_key = "#{key.to_s.downcase}:#{value.to_s}"
        @node_index[:by_property][index_key] ||= []
        @node_index[:by_property][index_key] << node
      end

      # Index by ID
      @node_index[:by_id][node[:id]] = node

    when :delete
      # Remove from label indexes
      node[:labels].each do |label|
        if @node_index[:by_label][label.to_s.downcase]
          @node_index[:by_label][label.to_s.downcase].delete(node)
          @node_index[:by_label].delete(label.to_s.downcase) if @node_index[:by_label][label.to_s.downcase].empty?
        end
      end

      # Remove from property indexes
      node[:properties].each do |key, value|
        index_key = "#{key.to_s.downcase}:#{value.to_s}"
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
      @relationship_index[:by_type][relationship[:type].to_s.downcase] ||= []
      @relationship_index[:by_type][relationship[:type].to_s.downcase] << relationship

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

  def update_node(node_id, labels, properties)
    node = @nodes[node_id]

    # Remove old indexes
    update_node_indexes(node, :delete)

    # Update node
    node[:labels] = labels
    node[:properties] = properties
    node[:updated_at] = Time.now

    # Add new indexes
    update_node_indexes(node, :create)

    node
  end
end
