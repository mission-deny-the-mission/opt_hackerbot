require_relative '../test_helper'
require_relative '../cag/in_memory_graph_client'

# Test suite for In-Memory Graph Client
class TestInMemoryGraphClient < Minitest::Test
  def setup
    @config = {
      provider: 'in_memory',
      max_nodes: 1000,
      max_relationships: 5000
    }
    @client = InMemoryGraphClient.new(@config)
  end

  def teardown
    @client.disconnect if @client
  end

  def test_initialization
    assert_instance_of InMemoryGraphClient, @client
    refute @client.connected?, "Client should not be connected initially"
    assert_equal @config, @client.instance_variable_get(:@config)
  end

  def test_connect_success
    result = @client.connect
    assert result, "Connection should succeed"
    assert @client.connected?, "Client should be connected after connect"
  end

  def test_disconnect_success
    @client.connect

    result = @client.disconnect
    assert result, "Disconnection should succeed"
    refute @client.connected?, "Client should not be connected after disconnect"
  end

  def test_create_node_success
    @client.connect

    node_id = 'test_node_1'
    labels = ['Test', 'Entity']
    properties = { name: 'Test Node', type: 'test' }

    result = @client.create_node(node_id, labels, properties)
    assert result, "Node creation should succeed"

    # Verify node was created
    nodes = @client.find_nodes_by_property('name', 'Test Node')
    assert_equal 1, nodes.length
    assert_equal node_id, nodes.first[:id]
  end

  def test_create_node_duplicate_id
    @client.connect

    node_id = 'duplicate_node'
    labels1 = ['Test']
    properties1 = { name: 'First Version' }
    properties2 = { name: 'Second Version' }

    # Create first node
    result1 = @client.create_node(node_id, labels1, properties1)
    assert result1, "First node creation should succeed"

    # Create second node with same ID (should update)
    result2 = @client.create_node(node_id, labels1, properties2)
    assert result2, "Second node creation with same ID should succeed"

    # Verify only one node exists with updated properties
    nodes = @client.find_nodes_by_property('name', 'Second Version')
    assert_equal 1, nodes.length
  end

  def test_create_node_without_connection
    # Should auto-connect
    result = @client.create_node('test_node', ['Test'], { name: 'Test' })
    assert result, "Node creation should auto-connect"
    assert @client.connected?, "Should be connected after auto-connect"
  end

  def test_create_relationship_success
    @client.connect

    # Create nodes first
    @client.create_node('node1', ['Test'], { name: 'Node 1' })
    @client.create_node('node2', ['Test'], { name: 'Node 2' })

    result = @client.create_relationship('node1', 'node2', 'RELATES_TO', { strength: 0.8 })
    assert result, "Relationship creation should succeed"

    # Verify relationship was created
    relationships = @client.find_relationships('node1', 'RELATES_TO')
    assert_equal 1, relationships.length
    assert_equal 'node2', relationships.first[:to]
  end

  def test_create_relationship_nonexistent_nodes
    @client.connect

    # Should create nodes automatically if they don't exist
    result = @client.create_relationship('nonexistent1', 'nonexistent2', 'RELATES_TO', {})
    assert result, "Relationship creation should auto-create nodes"

    # Verify nodes were created
    nodes1 = @client.find_nodes_by_property('name', 'nonexistent1')
    nodes2 = @client.find_nodes_by_property('name', 'nonexistent2')
    assert_equal 1, nodes1.length
    assert_equal 1, nodes2.length
  end

  def test_find_nodes_by_label_success
    @client.connect

    # Create test nodes
    @client.create_node('node1', ['Test', 'Entity'], { name: 'Node 1' })
    @client.create_node('node2', ['Test'], { name: 'Node 2' })
    @client.create_node('node3', ['Other'], { name: 'Node 3' })

    nodes = @client.find_nodes_by_label('Test')
    assert_equal 2, nodes.length
    assert nodes.all? { |node| node[:labels].include?('Test') }
  end

  def test_find_nodes_by_label_nonexistent
    @client.connect

    nodes = @client.find_nodes_by_label('Nonexistent')
    assert_empty nodes
  end

  def test_find_nodes_by_property_success
    @client.connect

    # Create test nodes
    @client.create_node('node1', ['Test'], { name: 'Node 1', type: 'A', value: 10 })
    @client.create_node('node2', ['Test'], { name: 'Node 2', type: 'A', value: 20 })
    @client.create_node('node3', ['Test'], { name: 'Node 3', type: 'B', value: 10 })

    # Test string property
    nodes = @client.find_nodes_by_property('type', 'A')
    assert_equal 2, nodes.length

    # Test numeric property
    nodes = @client.find_nodes_by_property('value', 10)
    assert_equal 2, nodes.length
  end

  def test_find_nodes_by_property_complex_values
    @client.connect

    # Create nodes with complex property values
    @client.create_node('node1', ['Test'], {
      name: 'Complex 1',
      metadata: { nested: { value: 'deep' } },
      tags: ['tag1', 'tag2']
    })

    @client.create_node('node2', ['Test'], {
      name: 'Complex 2',
      metadata: { nested: { value: 'shallow' } },
      tags: ['tag1', 'tag3']
    })

    # Test with array property
    nodes = @client.find_nodes_by_property('tags', ['tag1', 'tag2'])
    assert_equal 1, nodes.length
    assert_equal 'Complex 1', nodes.first[:properties][:name]
  end

  def test_find_relationships_comprehensive
    @client.connect

    # Create nodes
    @client.create_node('node1', ['Test'], { name: 'Node 1' })
    @client.create_node('node2', ['Test'], { name: 'Node 2' })
    @client.create_node('node3', ['Test'], { name: 'Node 3' })

    # Create various relationships
    @client.create_relationship('node1', 'node2', 'RELATES_TO', { strength: 0.8 })
    @client.create_relationship('node1', 'node3', 'DIFFERENT_REL', { strength: 0.5 })
    @client.create_relationship('node2', 'node1', 'INCOMING_REL', { strength: 0.9 })
    @client.create_relationship('node3', 'node1', 'INCOMING_REL', { strength: 0.7 })

    # Test all relationships from node1
    all_rels = @client.find_relationships('node1')
    assert_equal 3, all_rels.length

    # Test specific relationship type
    specific_rels = @client.find_relationships('node1', 'RELATES_TO')
    assert_equal 1, specific_rels.length
    assert_equal 'RELATES_TO', specific_rels.first[:type]

    # Test outgoing relationships
    outgoing_rels = @client.find_relationships('node1', nil, :outgoing)
    assert_equal 2, outgoing_rels.length
    assert outgoing_rels.all? { |rel| rel[:from] == 'node1' }

    # Test incoming relationships
    incoming_rels = @client.find_relationships('node1', nil, :incoming)
    assert_equal 1, incoming_rels.length
    assert incoming_rels.all? { |rel| rel[:to] == 'node1' }

    # Test combination of type and direction
    combined_rels = @client.find_relationships('node1', 'INCOMING_REL', :incoming)
    assert_equal 1, combined_rels.length
  end

  def test_search_nodes_success
    @client.connect

    # Create test nodes
    @client.create_node('node1', ['Test'], {
      name: 'Cybersecurity Node',
      description: 'About security and protection',
      tags: ['security', 'cyber']
    })
    @client.create_node('node2', ['Test'], {
      name: 'Network Security Node',
      description: 'About network protection',
      tags: ['network', 'security']
    })
    @client.create_node('node3', ['Test'], {
      name: 'Other Node',
      description: 'About other topics',
      tags: ['other']
    })

    # Search for 'security' - should match multiple nodes
    results = @client.search_nodes('security')
    assert_equal 2, results.length

    # Search for 'network' - should match one node
    results = @client.search_nodes('network')
    assert_equal 1, results.length
    assert_equal 'Network Security Node', results.first[:properties][:name]

    # Search for 'cyber' - should match one node
    results = @client.search_nodes('cyber')
    assert_equal 1, results.length
    assert_equal 'Cybersecurity Node', results.first[:properties][:name]
  end

  def test_search_nodes_case_insensitive
    @client.connect

    @client.create_node('node1', ['Test'], { name: 'Test Node' })
    @client.create_node('node2', ['Test'], { name: 'TEST NODE' })
    @client.create_node('node3', ['Test'], { name: 'test node' })

    results = @client.search_nodes('TEST')
    assert_equal 3, results.length

    results = @client.search_nodes('test')
    assert_equal 3, results.length

    results = @client.search_nodes('Test')
    assert_equal 3, results.length
  end

  def test_search_nodes_with_limit
    @client.connect

    # Create many nodes with similar content
    15.times do |i|
      @client.create_node("node#{i}", ['Test'], {
        name: "Test Node #{i}",
        description: "Test description #{i}"
      })
    end

    # Test with limit
    results = @client.search_nodes('test', 5)
    assert_equal 5, results.length

    # Test without limit (should return all)
    all_results = @client.search_nodes('test')
    assert_equal 15, all_results.length
  end

  def test_get_node_context_simple
    @client.connect

    # Create a simple connected graph
    @client.create_node('center', ['Test'], { name: 'Center Node' })
    @client.create_node('related1', ['Test'], { name: 'Related 1' })
    @client.create_node('related2', ['Test'], { name: 'Related 2' })

    # Create relationships
    @client.create_relationship('center', 'related1', 'RELATES_TO', {})
    @client.create_relationship('center', 'related2', 'RELATES_TO', {})

    # Get context for center node
    context = @client.get_node_context('center', 1, 10)
    assert_equal 2, context.length

    # Verify context contains expected nodes
    context_names = context.map { |node| node[:properties][:name] }
    assert_includes context_names, 'Related 1'
    assert_includes context_names, 'Related 2'
  end

  def test_get_node_context_deep
    @client.connect

    # Create a deeper graph structure
    @client.create_node('center', ['Test'], { name: 'Center' })
    @client.create_node('level1_1', ['Test'], { name: 'Level 1-1' })
    @client.create_node('level1_2', ['Test'], { name: 'Level 1-2' })
    @client.create_node('level2_1', ['Test'], { name: 'Level 2-1' })
    @client.create_node('level2_2', ['Test'], { name: 'Level 2-2' })
    @client.create_node('level3_1', ['Test'], { name: 'Level 3-1' })

    # Create relationships forming a tree structure
    @client.create_relationship('center', 'level1_1', 'CONNECTS_TO', {})
    @client.create_relationship('center', 'level1_2', 'CONNECTS_TO', {})
    @client.create_relationship('level1_1', 'level2_1', 'CONNECTS_TO', {})
    @client.create_relationship('level1_1', 'level2_2', 'CONNECTS_TO', {})
    @client.create_relationship('level2_1', 'level3_1', 'CONNECTS_TO', {})

    # Test different depths
    depth1_context = @client.get_node_context('center', 1, 20)
    assert_equal 2, depth1_context.length

    depth2_context = @client.get_node_context('center', 2, 20)
    assert_equal 4, depth2_context.length

    depth3_context = @client.get_node_context('center', 3, 20)
    assert_equal 5, depth3_context.length
  end

  def test_get_node_context_with_node_limit
    @client.connect

    # Create a star graph with many nodes
    @client.create_node('center', ['Test'], { name: 'Center' })
    10.times do |i|
      @client.create_node("satellite#{i}", ['Test'], { name: "Satellite #{i}" })
      @client.create_relationship('center', "satellite#{i}", 'CONNECTS_TO', {})
    end

    # Test with node limit
    limited_context = @client.get_node_context('center', 2, 3)
    assert_equal 3, limited_context.length
  end

  def test_get_node_context_nonexistent_node
    @client.connect

    context = @client.get_node_context('nonexistent')
    assert_empty context
  end

  def test_delete_node_success
    @client.connect

    # Create node and relationships
    @client.create_node('node1', ['Test'], { name: 'Node 1' })
    @client.create_node('node2', ['Test'], { name: 'Node 2' })
    @client.create_node('node3', ['Test'], { name: 'Node 3' })
    @client.create_relationship('node1', 'node2', 'RELATES_TO', {})
    @client.create_relationship('node1', 'node3', 'RELATES_TO', {})
    @client.create_relationship('node2', 'node3', 'RELATES_TO', {})

    result = @client.delete_node('node1')
    assert result, "Node deletion should succeed"

    # Verify node is gone
    nodes = @client.find_nodes_by_property('name', 'Node 1')
    assert_empty nodes

    # Verify relationships involving deleted node are gone
    rels_from_node2 = @client.find_relationships('node2')
    assert_equal 1, rels_from_node2.length  # Only node2->node3 should remain
    assert_equal 'node3', rels_from_node2.first[:to]

    rels_from_node3 = @client.find_relationships('node3')
    assert_empty rels_from_node3  # All relationships involving node3 should be gone except node2->node3
  end

  def test_delete_node_nonexistent
    @client.connect

    result = @client.delete_node('nonexistent')
    refute result, "Deleting nonexistent node should fail"
  end

  def test_test_connection_success
    @client.connect

    result = @client.test_connection
    assert result, "Connection test should succeed when connected"
  end

  def test_test_connection_failure
    result = @client.test_connection
    refute result, "Connection test should fail when not connected"
  end

  def test_graph_statistics
    @client.connect

    # Initially empty
    stats = @client.get_graph_statistics
    assert_equal 0, stats[:node_count]
    assert_equal 0, stats[:relationship_count]

    # Add nodes
    @client.create_node('node1', ['Test'], { name: 'Node 1' })
    @client.create_node('node2', ['Test'], { name: 'Node 2' })

    stats = @client.get_graph_statistics
    assert_equal 2, stats[:node_count]
    assert_equal 0, stats[:relationship_count]

    # Add relationships
    @client.create_relationship('node1', 'node2', 'RELATES_TO', {})

    stats = @client.get_graph_statistics
    assert_equal 2, stats[:node_count]
    assert_equal 1, stats[:relationship_count]
  end

  def test_export_import_graph
    @client.connect

    # Create a test graph
    @client.create_node('node1', ['Test'], { name: 'Node 1', value: 10 })
    @client.create_node('node2', ['Test'], { name: 'Node 2', value: 20 })
    @client.create_relationship('node1', 'node2', 'RELATES_TO', { strength: 0.8 })

    # Export graph
    exported_data = @client.export_graph
    assert_instance_of Hash, exported_data
    assert_equal 2, exported_data[:nodes].length
    assert_equal 1, exported_data[:relationships].length

    # Create new client and import
    new_client = InMemoryGraphClient.new(@config)
    new_client.connect

    result = new_client.import_graph(exported_data)
    assert result, "Graph import should succeed"

    # Verify imported data
    imported_nodes = new_client.find_nodes_by_label('Test')
    assert_equal 2, imported_nodes.length

    imported_rels = new_client.find_relationships('node1')
    assert_equal 1, imported_rels.length

    new_client.disconnect
  end

  def test_large_graph_performance
    @client.connect

    # Create a large number of nodes and relationships
    node_count = 500
    relationship_count = 1000

    start_time = Time.now

    # Create nodes
    node_count.times do |i|
      @client.create_node("large_node_#{i}", ['Test'], {
        name: "Large Node #{i}",
        index: i
      })
    end

    # Create relationships
    relationship_count.times do |i|
      from = "large_node_#{i % node_count}"
      to = "large_node_#{(i + 50) % node_count}"  # Create some distance
      @client.create_relationship(from, to, 'RELATES_TO', { weight: rand })
    end

    creation_time = Time.now - start_time
    puts "Large graph creation time: #{creation_time.round(2)}s"

    # Test search performance
    search_start = Time.now
    results = @client.search_nodes('node', 100)
    search_time = Time.now - search_start
    puts "Search time: #{search_time.round(4)}s for #{results.length} results"

    # Test context retrieval performance
    context_start = Time.now
    context = @client.get_node_context('large_node_0', 3, 50)
    context_time = Time.now - context_start
    puts "Context retrieval time: #{context_time.round(4)}s for #{context.length} nodes"

    # Verify basic functionality still works
    assert_equal node_count, @client.get_graph_statistics[:node_count]
    assert_equal relationship_count, @client.get_graph_statistics[:relationship_count]
    assert_equal 100, results.length
    refute_empty context
  end

  def test_concurrent_operations
    @client.connect

    threads = []
    results = []

    # Concurrent node creation
    10.times do |i|
      threads << Thread.new do
        thread_result = @client.create_node("concurrent_node_#{i}", ['Test'], {
          name: "Concurrent #{i}",
          thread_id: i
        })
        results << { operation: 'create_node', result: thread_result, id: i }
      end
    end

    # Concurrent relationship creation
    10.times do |i|
      threads << Thread.new do
        from = "concurrent_node_#{i}"
        to = "concurrent_node_#{(i + 1) % 10}"
        thread_result = @client.create_relationship(from, to, 'THREAD_REL', {})
        results << { operation: 'create_relationship', result: thread_result, id: i }
      end
    end

    threads.each(&:join)

    # All operations should succeed
    create_results = results.select { |r| r[:operation] == 'create_node' }
    rel_results = results.select { |r| r[:operation] == 'create_relationship' }

    assert_equal 10, create_results.length
    assert_equal 10, rel_results.length
    assert create_results.all? { |r| r[:result] }
    assert rel_results.all? { |r| r[:result] }

    # Verify consistency
    all_nodes = @client.find_nodes_by_label('Test')
    assert_equal 10, all_nodes.length

    all_rels = @client.find_relationships('concurrent_node_0')
    assert_equal 2, all_rels.length  # One outgoing, one incoming
  end

  def test_memory_usage_cleanup
    @client.connect

    # Create a large graph
    100.times do |i|
      @client.create_node("memory_node_#{i}", ['Test'], { name: "Memory Node #{i}" })
      @client.create_relationship("memory_node_#{i}", "memory_node_#{(i + 1) % 100}", 'CONNECTS_TO', {})
    end

    # Verify graph exists
    stats = @client.get_graph_statistics
    assert_equal 100, stats[:node_count]
    assert_equal 100, stats[:relationship_count]

    # Disconnect and verify cleanup
    @client.disconnect

    # Reconnect and verify graph is empty
    @client.connect
    stats = @client.get_graph_statistics
    assert_equal 0, stats[:node_count]
    assert_equal 0, stats[:relationship_count]
  end

  def test_error_handling_edge_cases
    @client.connect

    # Test with very long node IDs
    long_id = 'a' * 1000
    result = @client.create_node(long_id, ['Test'], { name: 'Long ID Node' })
    assert result, "Should handle very long node IDs"

    # Test with very large property values
    large_value = 'x' * 50000  # 50KB
    result = @client.create_node('large_prop_node', ['Test'], { large_text: large_value })
    assert result, "Should handle very large property values"

    # Test with circular relationships
    @client.create_node('circular1', ['Test'], {})
    @client.create_node('circular2', ['Test'], {})
    @client.create_relationship('circular1', 'circular2', 'CIRCULAR', {})
    @client.create_relationship('circular2', 'circular1', 'CIRCULAR', {})

    # Should handle circular relationships without infinite loops
    context = @client.get_node_context('circular1', 5, 20)
    assert_equal 1, context.length  # Should find circular2 but stop due to depth limit
  end

  def test_graph_traversal_correctness
    @client.connect

    # Create a specific graph structure for testing traversal
    # A -> B -> C -> D
    # |         |
    # v         v
    # E -> F -> G

    nodes = %w[A B C D E F G]
    nodes.each { |node| @client.create_node(node, ['Test'], { name: node }) }

    # Create relationships
    @client.create_relationship('A', 'B', 'TO', {})
    @client.create_relationship('B', 'C', 'TO', {})
    @client.create_relationship('C', 'D', 'TO', {})
    @client.create_relationship('A', 'E', 'TO', {})
    @client.create_relationship('E', 'F', 'TO', {})
    @client.create_relationship('C', 'G', 'TO', {})
    @client.create_relationship('F', 'G', 'TO', {})

    # Test traversal from A with different depths
    depth1 = @client.get_node_context('A', 1, 20)
    depth1_names = depth1.map { |n| n[:properties][:name] }
    assert_equal %w[B E], depth1_names.sort

    depth2 = @client.get_node_context('A', 2, 20)
    depth2_names = depth2.map { |n| n[:properties][:name] }
    assert_equal %w[B C E F], depth2_names.sort

    depth3 = @client.get_node_context('A', 3, 20)
    depth3_names = depth3.map { |n| n[:properties][:name] }
    assert_equal %w[B C D E F G], depth3_names.sort
  end
end
