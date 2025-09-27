require_relative '../test_helper'
require_relative '../cag/knowledge_graph_interface'

# Mock knowledge graph for testing
class MockKnowledgeGraph < KnowledgeGraphInterface
  def initialize(config)
    super(config)
    @nodes = {}
    @relationships = []
  end

  def connect
    @initialized = true
    true
  end

  def disconnect
    @nodes.clear
    @relationships.clear
    @initialized = false
    true
  end

  def create_node(node_id, labels, properties)
    validate_node_id(node_id)
    validate_labels(labels)
    validate_properties(properties)

    @nodes[node_id] = {
      id: node_id,
      labels: labels,
      properties: properties || {},
      created_at: Time.now
    }
    true
  end

  def create_relationship(from_node_id, to_node_id, relationship_type, properties)
    validate_node_id(from_node_id)
    validate_node_id(to_node_id)
    validate_relationship_type(relationship_type)
    validate_properties(properties)

    relationship = {
      from: from_node_id,
      to: to_node_id,
      type: relationship_type,
      properties: properties || {},
      created_at: Time.now
    }

    @relationships << relationship
    true
  end

  def find_nodes_by_label(label, limit = 10)
    nodes = @nodes.values.select { |node| node[:labels].include?(label) }
    nodes.take(limit)
  end

  def find_nodes_by_property(property_name, property_value, limit = 10)
    nodes = @nodes.values.select do |node|
      node[:properties][property_name] == property_value
    end
    nodes.take(limit)
  end

  def find_relationships(node_id, relationship_type = nil, direction = nil)
    relationships = @relationships.select do |rel|
      match = true
      match &&= rel[:type] == relationship_type if relationship_type
      match &&= rel[:from] == node_id if direction == :outgoing || direction.nil?
      match &&= rel[:to] == node_id if direction == :incoming || direction.nil?
      match
    end
    relationships
  end

  def search_nodes(search_query, limit = 10)
    normalized_query = normalize_search_query(search_query)
    return [] unless normalized_query

    matching_nodes = @nodes.values.select do |node|
      # Search in node properties, especially name
      node[:properties].values.any? do |value|
        value.to_s.downcase.include?(normalized_query)
      end
    end
    matching_nodes.take(limit)
  end

  def get_node_context(node_id, max_depth = 2, max_nodes = 20)
    return [] unless @nodes.key?(node_id)

    context_nodes = []
    processed_nodes = Set.new([node_id])
    current_level = [node_id]

    max_depth.times do
      next_level = []

      current_level.each do |current_node_id|
        # Get outgoing relationships
        outgoing_rels = find_relationships(current_node_id, nil, :outgoing)
        outgoing_rels.each do |rel|
          target_id = rel[:to]
          next if processed_nodes.include?(target_id)

          if @nodes.key?(target_id)
            context_nodes << @nodes[target_id]
            processed_nodes.add(target_id)
            next_level << target_id
          end
        end

        # Get incoming relationships
        incoming_rels = find_relationships(current_node_id, nil, :incoming)
        incoming_rels.each do |rel|
          source_id = rel[:from]
          next if processed_nodes.include?(source_id)

          if @nodes.key?(source_id)
            context_nodes << @nodes[source_id]
            processed_nodes.add(source_id)
            next_level << source_id
          end
        end

        break if context_nodes.length >= max_nodes
      end

      current_level = next_level
      break if context_nodes.length >= max_nodes
    end

    context_nodes.take(max_nodes)
  end

  def delete_node(node_id)
    validate_node_id(node_id)
    return false unless @nodes.key?(node_id)

    # Remove node
    @nodes.delete(node_id)

    # Remove relationships involving this node
    @relationships.reject! do |rel|
      rel[:from] == node_id || rel[:to] == node_id
    end

    true
  end

  def test_connection
    @initialized
  end
end

# Test suite for Knowledge Graph Interface
class TestKnowledgeGraphInterface < Minitest::Test
  def setup
    @config = { provider: 'mock' }
    @graph = MockKnowledgeGraph.new(@config)
  end

  def teardown
    @graph.disconnect if @graph
  end

  def test_initialization
    assert_instance_of MockKnowledgeGraph, @graph
    refute @graph.connected?, "Graph should not be connected initially"
    assert_equal @config, @graph.instance_variable_get(:@config)
  end

  def test_connect_success
    result = @graph.connect
    assert result, "Connection should succeed"
    assert @graph.connected?, "Graph should be connected after connect"
  end

  def test_disconnect_success
    @graph.connect

    result = @graph.disconnect
    assert result, "Disconnection should succeed"
    refute @graph.connected?, "Graph should not be connected after disconnect"
  end

  def test_create_node_success
    @graph.connect

    node_id = 'test_node_1'
    labels = ['Test', 'Entity']
    properties = { name: 'Test Node', type: 'test' }

    result = @graph.create_node(node_id, labels, properties)
    assert result, "Node creation should succeed"
  end

  def test_create_node_invalid_node_id
    @graph.connect

    assert_raises ArgumentError do
      @graph.create_node(nil, ['Test'], {})
    end

    assert_raises ArgumentError do
      @graph.create_node('', ['Test'], {})
    end
  end

  def test_create_node_invalid_labels
    @graph.connect

    assert_raises ArgumentError do
      @graph.create_node('test_node', nil, {})
    end

    assert_raises ArgumentError do
      @graph.create_node('test_node', [], {})
    end

    assert_raises ArgumentError do
      @graph.create_node('test_node', [''], {})
    end

    assert_raises ArgumentError do
      @graph.create_node('test_node', ['invalid@label'], {})
    end
  end

  def test_create_node_invalid_properties
    @graph.connect

    # Test with non-hash properties
    assert_raises ArgumentError do
      @graph.create_node('test_node', ['Test'], 'invalid')
    end

    # Test with non-serializable properties
    assert_raises ArgumentError do
      @graph.create_node('test_node', ['Test'], { proc: -> {} })
    end
  end

  def test_create_relationship_success
    @graph.connect

    # Create nodes first
    @graph.create_node('node1', ['Test'], { name: 'Node 1' })
    @graph.create_node('node2', ['Test'], { name: 'Node 2' })

    result = @graph.create_relationship('node1', 'node2', 'RELATES_TO', { strength: 0.8 })
    assert result, "Relationship creation should succeed"
  end

  def test_create_relationship_invalid_nodes
    @graph.connect

    assert_raises ArgumentError do
      @graph.create_relationship(nil, 'node2', 'RELATES_TO', {})
    end

    assert_raises ArgumentError do
      @graph.create_relationship('node1', nil, 'RELATES_TO', {})
    end
  end

  def test_create_relationship_invalid_type
    @graph.connect

    @graph.create_node('node1', ['Test'], {})
    @graph.create_node('node2', ['Test'], {})

    assert_raises ArgumentError do
      @graph.create_relationship('node1', 'node2', '', {})
    end

    assert_raises ArgumentError do
      @graph.create_relationship('node1', 'node2', 'invalid_type', {})
    end

    assert_raises ArgumentError do
      @graph.create_relationship('node1', 'node2', 'lowercase_type', {})
    end
  end

  def test_find_nodes_by_label_success
    @graph.connect

    # Create test nodes
    @graph.create_node('node1', ['Test', 'Entity'], { name: 'Node 1' })
    @graph.create_node('node2', ['Test'], { name: 'Node 2' })
    @graph.create_node('node3', ['Other'], { name: 'Node 3' })

    nodes = @graph.find_nodes_by_label('Test')
    assert_equal 2, nodes.length
    assert nodes.all? { |node| node[:labels].include?('Test') }
  end

  def test_find_nodes_by_label_with_limit
    @graph.connect

    # Create many nodes
    10.times do |i|
      @graph.create_node("node#{i}", ['Test'], { name: "Node #{i}" })
    end

    nodes = @graph.find_nodes_by_label('Test', 3)
    assert_equal 3, nodes.length
  end

  def test_find_nodes_by_property_success
    @graph.connect

    # Create test nodes
    @graph.create_node('node1', ['Test'], { name: 'Node 1', type: 'A' })
    @graph.create_node('node2', ['Test'], { name: 'Node 2', type: 'A' })
    @graph.create_node('node3', ['Test'], { name: 'Node 3', type: 'B' })

    nodes = @graph.find_nodes_by_property('type', 'A')
    assert_equal 2, nodes.length
    assert nodes.all? { |node| node[:properties]['type'] == 'A' }
  end

  def test_find_nodes_by_property_nonexistent
    @graph.connect

    nodes = @graph.find_nodes_by_property('nonexistent', 'value')
    assert_empty nodes
  end

  def test_find_relationships_success
    @graph.connect

    # Create nodes and relationships
    @graph.create_node('node1', ['Test'], {})
    @graph.create_node('node2', ['Test'], {})
    @graph.create_node('node3', ['Test'], {})

    @graph.create_relationship('node1', 'node2', 'RELATES_TO', {})
    @graph.create_relationship('node1', 'node3', 'DIFFERENT_REL', {})
    @graph.create_relationship('node2', 'node1', 'INCOMING_REL', {})

    # Test all relationships from node1
    rels = @graph.find_relationships('node1')
    assert_equal 2, rels.length

    # Test specific relationship type
    specific_rels = @graph.find_relationships('node1', 'RELATES_TO')
    assert_equal 1, specific_rels.length

    # Test outgoing relationships
    outgoing_rels = @graph.find_relationships('node1', nil, :outgoing)
    assert_equal 2, outgoing_rels.length

    # Test incoming relationships
    incoming_rels = @graph.find_relationships('node1', nil, :incoming)
    assert_equal 1, incoming_rels.length
  end

  def test_search_nodes_success
    @graph.connect

    # Create test nodes
    @graph.create_node('node1', ['Test'], { name: 'Cybersecurity Node', description: 'About security' })
    @graph.create_node('node2', ['Test'], { name: 'Network Node', description: 'About networking' })
    @graph.create_node('node3', ['Test'], { name: 'Other Node', description: 'About other topics' })

    # Search for 'security'
    results = @graph.search_nodes('security')
    assert_equal 1, results.length
    assert_equal 'Cybersecurity Node', results.first[:properties][:name]

    # Search for 'network'
    results = @graph.search_nodes('network')
    assert_equal 1, results.length
    assert_equal 'Network Node', results.first[:properties][:name]
  end

  def test_search_nodes_case_insensitive
    @graph.connect

    @graph.create_node('node1', ['Test'], { name: 'Test Node' })

    results = @graph.search_nodes('TEST')
    assert_equal 1, results.length

    results = @graph.search_nodes('test')
    assert_equal 1, results.length
  end

  def test_search_nodes_with_limit
    @graph.connect

    # Create many nodes with similar content
    10.times do |i|
      @graph.create_node("node#{i}", ['Test'], { name: "Test Node #{i}" })
    end

    results = @graph.search_nodes('test', 3)
    assert_equal 3, results.length
  end

  def test_get_node_context_success
    @graph.connect

    # Create a connected graph
    @graph.create_node('center', ['Test'], { name: 'Center Node' })
    @graph.create_node('related1', ['Test'], { name: 'Related 1' })
    @graph.create_node('related2', ['Test'], { name: 'Related 2' })
    @graph.create_node('distant', ['Test'], { name: 'Distant' })

    # Create relationships
    @graph.create_relationship('center', 'related1', 'RELATES_TO', {})
    @graph.create_relationship('center', 'related2', 'RELATES_TO', {})
    @graph.create_relationship('related1', 'distant', 'CONNECTS_TO', {})

    # Get context for center node
    context = @graph.get_node_context('center', 2, 10)
    assert_equal 2, context.length  # Should find related1 and related2

    # Get deeper context
    deep_context = @graph.get_node_context('center', 3, 10)
    assert_equal 3, deep_context.length  # Should find all nodes
  end

  def test_get_node_context_with_limits
    @graph.connect

    # Create many connected nodes
    @graph.create_node('center', ['Test'], { name: 'Center' })
    10.times do |i|
      @graph.create_node("node#{i}", ['Test'], { name: "Node #{i}" })
      @graph.create_relationship('center', "node#{i}", 'RELATES_TO', {})
    end

    # Test depth limit
    shallow_context = @graph.get_node_context('center', 1, 20)
    assert_equal 10, shallow_context.length

    # Test node limit
    limited_context = @graph.get_node_context('center', 2, 3)
    assert_equal 3, limited_context.length
  end

  def test_get_node_context_nonexistent_node
    @graph.connect

    context = @graph.get_node_context('nonexistent')
    assert_empty context
  end

  def test_delete_node_success
    @graph.connect

    # Create node and relationships
    @graph.create_node('node1', ['Test'], { name: 'Node 1' })
    @graph.create_node('node2', ['Test'], { name: 'Node 2' })
    @graph.create_relationship('node1', 'node2', 'RELATES_TO', {})

    result = @graph.delete_node('node1')
    assert result, "Node deletion should succeed"

    # Verify node is gone
    nodes = @graph.find_nodes_by_property('name', 'Node 1')
    assert_empty nodes

    # Verify relationships are gone
    rels = @graph.find_relationships('node2')
    assert_empty rels
  end

  def test_delete_node_invalid_id
    @graph.connect

    assert_raises ArgumentError do
      @graph.delete_node(nil)
    end

    assert_raises ArgumentError do
      @graph.delete_node('')
    end
  end

  def test_delete_nonexistent_node
    @graph.connect

    result = @graph.delete_node('nonexistent')
    refute result, "Deleting nonexistent node should fail"
  end

  def test_test_connection_success
    @graph.connect

    result = @graph.test_connection
    assert result, "Connection test should succeed when connected"
  end

  def test_test_connection_failure
    result = @graph.test_connection
    refute result, "Connection test should fail when not connected"
  end

  def test_connected_helper_method
    refute @graph.connected?, "Should not be connected initially"

    @graph.connect
    assert @graph.connected?, "Should be connected after connect"

    @graph.disconnect
    refute @graph.connected?, "Should not be connected after disconnect"
  end

  def test_normalize_search_query
    @graph.connect

    normalized = @graph.send(:normalize_search_query, "Hello World! Test@123")
    assert_equal "hello world test123", normalized

    normalized = @graph.send(:normalize_search_query, "  Extra   Spaces  ")
    assert_equal "extra spaces", normalized

    normalized = @graph.send(:normalize_search_query, nil)
    assert_nil normalized
  end

  def test_create_id_from_text
    @graph.connect

    id = @graph.send(:create_id_from_text, "Test Entity", "prefix")
    assert_equal "prefix_test_entity", id

    id = @graph.send(:create_id_from_text, "Multiple Words Here", "entity")
    assert_equal "entity_multiple_words_here", id

    id = @graph.send(:create_id_from_text, nil, "prefix")
    assert_nil id
  end

  def test_extract_entities_from_text
    @graph.connect

    text = "Attack from 192.168.1.100 using http://malicious.com/malware.exe. Email: attacker@example.com on port 4444. Hash: 1a2b3c4d5e6f7890abcdef1234567890abcdef1234"

    entities = @graph.extract_entities_from_text(text)
    assert_instance_of Array, entities
    refute_empty entities

    # Check specific entity types
    ip_entities = entities.select { |e| e[:type] == 'ip_address' }
    url_entities = entities.select { |e| e[:type] == 'url' }
    email_entities = entities.select { |e| e[:type] == 'email' }
    port_entities = entities.select { |e| e[:type] == 'port' }
    hash_entities = entities.select { |e| e[:type] == 'hash' }

    assert_equal 1, ip_entities.length
    assert_equal '192.168.1.100', ip_entities.first[:value]

    assert_equal 1, url_entities.length
    assert_equal 'http://malicious.com/malware.exe', url_entities.first[:value]

    assert_equal 1, email_entities.length
    assert_equal 'attacker@example.com', email_entities.first[:value]

    assert_equal 1, port_entities.length
    assert_equal '4444', port_entities.first[:value]

    assert_equal 1, hash_entities.length
    assert_equal '1a2b3c4d5e6f7890abcdef1234567890abcdef1234', hash_entities.first[:value]
  end

  def test_extract_entities_with_type_filtering
    @graph.connect

    text = "IP: 192.168.1.100, URL: http://test.com, Email: test@example.com"

    # Extract only IP addresses
    entities = @graph.extract_entities_from_text(text, ['ip_address'])
    assert_equal 1, entities.length
    assert_equal 'ip_address', entities.first[:type]

    # Extract only URLs
    entities = @graph.extract_entities_from_text(text, ['url'])
    assert_equal 1, entities.length
    assert_equal 'url', entities.first[:type]
  end

  def test_extract_entities_empty_text
    @graph.connect

    entities = @graph.extract_entities_from_text("")
    assert_empty entities

    entities = @graph.extract_entities_from_text(nil)
    assert_empty entities
  end

  def test_concurrent_operations
    @graph.connect

    threads = []
    results = []

    # Concurrent node creation
    5.times do |i|
      threads << Thread.new do
        result = @graph.create_node("concurrent_node_#{i}", ['Test'], { name: "Concurrent #{i}" })
        results << result
      end
    end

    threads.each(&:join)

    # All operations should succeed
    assert_equal 5, results.length
    results.each { |result| assert result }

    # Verify all nodes were created
    all_nodes = @graph.find_nodes_by_label('Test')
    assert_equal 5, all_nodes.length
  end

  def test_large_graph_operations
    @graph.connect

    # Create a large number of nodes and relationships
    node_count = 100
    relationship_count = 200

    # Create nodes
    node_count.times do |i|
      @graph.create_node("large_node_#{i}", ['Test'], { name: "Large Node #{i}" })
    end

    # Create relationships
    relationship_count.times do |i|
      from = "large_node_#{i % node_count}"
      to = "large_node_#{(i + 1) % node_count}"
      @graph.create_relationship(from, to, 'RELATES_TO', {})
    end

    # Verify operations succeeded
    all_nodes = @graph.find_nodes_by_label('Test')
    assert_equal node_count, all_nodes.length

    # Test search performance
    results = @graph.search_nodes('node', 10)
    assert_equal 10, results.length

    # Test context retrieval on a complex graph
    context = @graph.get_node_context('large_node_0', 3, 20)
    refute_empty context
  end

  def test_error_handling_edge_cases
    @graph.connect

    # Test with very long node IDs
    long_id = 'a' * 1000
    result = @graph.create_node(long_id, ['Test'], {})
    assert result, "Should handle very long node IDs"

    # Test with very long property values
    long_value = 'x' * 10000
    result = @graph.create_node('test_node', ['Test'], { long_text: long_value })
    assert result, "Should handle very long property values"

    # Test with special characters in properties
    special_props = {
      unicode: "测试 中文",
      emojis: "🚀 🔒 🛡️",
      symbols: "@#$%^&*()",
      newlines: "Line1\nLine2\nLine3"
    }
    result = @graph.create_node('special_node', ['Test'], special_props)
    assert result, "Should handle special characters in properties"
  end

  def test_knowledge_graph_interface_abstract_methods
    # Test that abstract methods raise NotImplementedError
    abstract_graph = KnowledgeGraphInterface.new({})

    assert_raises NotImplementedError do
      abstract_graph.connect
    end

    assert_raises NotImplementedError do
      abstract_graph.disconnect
    end

    assert_raises NotImplementedError do
      abstract_graph.create_node('test', ['Test'], {})
    end

    assert_raises NotImplementedError do
      abstract_graph.create_relationship('from', 'to', 'RELATES', {})
    end

    assert_raises NotImplementedError do
      abstract_graph.find_nodes_by_label('Test')
    end

    assert_raises NotImplementedError do
      abstract_graph.find_nodes_by_property('name', 'value')
    end

    assert_raises NotImplementedError do
      abstract_graph.find_relationships('node_id')
    end

    assert_raises NotImplementedError do
      abstract_graph.search_nodes('query')
    end

    assert_raises NotImplementedError do
      abstract_graph.get_node_context('node_id')
    end

    assert_raises NotImplementedError do
      abstract_graph.delete_node('node_id')
    end

    assert_raises NotImplementedError do
      abstract_graph.test_connection
    end
  end
end
