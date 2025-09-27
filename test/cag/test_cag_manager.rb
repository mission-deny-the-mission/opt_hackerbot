require_relative '../test_helper'
require_relative '../cag/cag_manager'
require_relative '../cag/in_memory_graph_client'

# Test suite for CAG Manager
class TestCAGManager < Minitest::Test
  def setup
    @knowledge_graph_config = {
      provider: 'in_memory'
    }

    @entity_extractor_config = {
      provider: 'rule_based'
    }

    @cag_config = {
      max_context_depth: 2,
      max_context_nodes: 20,
      entity_types: ['ip_address', 'url', 'hash', 'filename', 'port', 'email'],
      enable_cross_reference: true,
      enable_caching: true
    }

    @manager = CAGManager.new(@knowledge_graph_config, @entity_extractor_config, @cag_config)
  end

  def teardown
    @manager.cleanup if @manager
  end

  def test_initialization
    assert_instance_of CAGManager, @manager
    refute @manager.initialized?, "Manager should not be initialized initially"
  end

  def test_setup_success
    result = @manager.setup
    assert result, "Setup should succeed"
    assert @manager.initialized?, "Manager should be initialized after setup"
  end

  def test_setup_with_invalid_config
    invalid_config = @knowledge_graph_config.merge(provider: 'invalid_provider')

    assert_raises ArgumentError do
      CAGManager.new(invalid_config, @entity_extractor_config, @cag_config)
    end
  end

  def test_extract_entities_success
    @manager.setup

    test_text = "The attack came from 192.168.1.100 using http://malicious.com/malware.exe"
    entities = @manager.extract_entities(test_text)

    assert_instance_of Array, entities
    refute_empty entities

    # Should extract IP address and URL
    ip_entities = entities.select { |e| e[:type] == 'ip_address' }
    url_entities = entities.select { |e| e[:type] == 'url' }

    assert_equal 1, ip_entities.length
    assert_equal '192.168.1.100', ip_entities.first[:value]
    assert_equal 1, url_entities.length
    assert_equal 'http://malicious.com/malware.exe', url_entities.first[:value]
  end

  def test_extract_entities_with_custom_types
    @manager.setup

    test_text = "Found file suspicious.dll with hash 1a2b3c4d5e6f7890abcdef1234567890abcdef1234"
    custom_types = ['hash', 'filename']

    entities = @manager.extract_entities(test_text, custom_types)

    assert_instance_of Array, entities
    refute_empty entities

    # Should only extract requested entity types
    hash_entities = entities.select { |e| e[:type] == 'hash' }
    filename_entities = entities.select { |e| e[:type] == 'filename' }

    assert_equal 1, hash_entities.length
    assert_equal 1, filename_entities.length

    # Should not extract other types
    ip_entities = entities.select { |e| e[:type] == 'ip_address' }
    assert_empty ip_entities
  end

  def test_extract_entities_empty_text
    @manager.setup

    entities = @manager.extract_entities("")
    assert_instance_of Array, entities
    assert_empty entities
  end

  def test_extract_entities_nil_text
    @manager.setup

    entities = @manager.extract_entities(nil)
    assert_instance_of Array, entities
    assert_empty entities
  end

  def test_extract_entities_without_setup
    # Should auto-initialize
    entities = @manager.extract_entities("Test text with IP 192.168.1.1")
    assert_instance_of Array, entities
    refute_empty entities
    assert @manager.initialized?, "Should be auto-initialized"
  end

  def test_expand_context_with_entities
    @manager.setup

    entities = [
      { type: 'ip_address', value: '192.168.1.100' },
      { type: 'url', value: 'http://malicious.com' }
    ]

    context_nodes = @manager.expand_context_with_entities(entities)
    assert_instance_of Array, context_nodes
  end

  def test_expand_context_with_depth_limit
    @manager.setup

    entities = [{ type: 'ip_address', value: '192.168.1.100' }]

    # Test with different depth limits
    shallow_context = @manager.expand_context_with_entities(entities, 1, 10)
    deep_context = @manager.expand_context_with_entities(entities, 3, 10)

    assert_instance_of Array, shallow_context
    assert_instance_of Array, deep_context
  end

  def test_get_context_for_query_success
    @manager.setup

    query = "What is known about the IP address 192.168.1.100?"
    context = @manager.get_context_for_query(query)

    refute_nil context
    assert_instance_of String, context
  end

  def test_get_context_for_query_with_caching
    @manager.setup

    query = "Test query for caching"

    # First call - should cache
    context1 = @manager.get_context_for_query(query)

    # Second call - should use cache
    context2 = @manager.get_context_for_query(query)

    assert_equal context1, context2, "Cached context should match"
  end

  def test_get_context_for_query_empty_query
    @manager.setup

    context = @manager.get_context_for_query("")
    refute_nil context, "Should handle empty query gracefully"
  end

  def test_get_context_for_query_without_setup
    # Should auto-initialize
    context = @manager.get_context_for_query("Test query")
    refute_nil context
    assert @manager.initialized?, "Should be auto-initialized"
  end

  def test_add_knowledge_triplet_success
    @manager.setup

    result = @manager.add_knowledge_triplet("Mimikatz", "IS_TYPE", "Malware")
    assert result, "Adding knowledge triplet should succeed"
  end

  def test_add_knowledge_triplet_with_properties
    @manager.setup

    properties = { severity: 'High', confidence: 0.9 }
    result = @manager.add_knowledge_triplet("Phishing", "HAS_TECHNIQUE", "Email Spoofing", properties)
    assert result, "Adding knowledge triplet with properties should succeed"
  end

  def test_add_knowledge_triplet_without_setup
    # Should auto-initialize
    result = @manager.add_knowledge_triplet("Test", "RELATES_TO", "Subject")
    assert result, "Should auto-initialize and add triplet"
    assert @manager.initialized?, "Should be auto-initialized"
  end

  def test_find_related_entities_success
    @manager.setup

    # First add some knowledge
    @manager.add_knowledge_triplet("Mimikatz", "IS_TYPE", "Malware")
    @manager.add_knowledge_triplet("Mimikatz", "USES_TECHNIQUE", "Credential Dumping")

    related_entities = @manager.find_related_entities("Mimikatz")
    assert_instance_of Array, related_entities
  end

  def test_find_related_entities_with_relationship_type
    @manager.setup

    @manager.add_knowledge_triplet("Mimikatz", "IS_TYPE", "Malware")
    @manager.add_knowledge_triplet("Mimikatz", "TARGETS", "Windows")

    # Find related entities by specific relationship
    related_entities = @manager.find_related_entities("Mimikatz", "IS_TYPE")
    assert_instance_of Array, related_entities
  end

  def test_find_related_entities_nonexistent_entity
    @manager.setup

    related_entities = @manager.find_related_entities("NonexistentEntity")
    assert_instance_of Array, related_entities
    assert_empty related_entities, "Should return empty array for nonexistent entity"
  end

  def test_create_knowledge_base_from_triplets_success
    @manager.setup

    triplets = [
      { subject: "Mimikatz", relationship: "IS_TYPE", object: "Malware", properties: { severity: "High" } },
      { subject: "Phishing", relationship: "IS_TYPE", object: "Attack", properties: { severity: "Medium" } },
      { subject: "Ransomware", relationship: "IS_TYPE", object: "Malware", properties: { severity: "Critical" } }
    ]

    result = @manager.create_knowledge_base_from_triplets(triplets)
    assert result, "Creating knowledge base from triplets should succeed"
  end

  def test_create_knowledge_base_from_triplets_batch_processing
    @manager.setup

    # Create many triplets to test batch processing
    triplets = []
    50.times do |i|
      triplets << {
        subject: "Entity_#{i}",
        relationship: "RELATES_TO",
        object: "Target_#{i}",
        properties: { batch_id: i }
      }
    end

    result = @manager.create_knowledge_base_from_triplets(triplets, 10) # batch_size = 10
    assert result, "Batch processing should succeed"
  end

  def test_create_knowledge_base_from_triplets_empty_array
    @manager.setup

    result = @manager.create_knowledge_base_from_triplets([])
    assert result, "Should handle empty triplets array"
  end

  def test_connection_test_success
    @manager.setup

    result = @manager.test_connection
    assert result, "Connection test should succeed"
  end

  def test_connection_test_failure
    # Create manager with invalid config
    invalid_config = @knowledge_graph_config.merge(provider: 'invalid_provider')

    assert_raises ArgumentError do
      CAGManager.new(invalid_config, @entity_extractor_config, @cag_config)
    end
  end

  def test_cleanup
    @manager.setup
    @manager.add_knowledge_triplet("Test", "RELATES_TO", "Subject")

    assert @manager.initialized?, "Should be initialized before cleanup"

    @manager.cleanup

    refute @manager.initialized?, "Should not be initialized after cleanup"
  end

  def test_entity_extraction_comprehensive
    @manager.setup

    test_messages = [
      "Attack from 192.168.1.100 using http://evil.com/malware.exe",
      "Found file suspicious.dll with hash 1a2b3c4d5e6f7890abcdef1234567890abcdef1234",
      "Connected to server on port 4444",
      "Email from john.doe@example.com",
      "Multiple IPs: 10.0.0.1, 172.16.0.1, 192.168.1.1"
    ]

    test_messages.each do |message|
      entities = @manager.extract_entities(message)
      assert_instance_of Array, entities
      refute_empty entities, "Should extract entities from: #{message}"
    end
  end

  def test_context_expansion_limits
    @manager.setup

    entities = [
      { type: 'ip_address', value: '192.168.1.100' },
      { type: 'url', value: 'http://malicious.com' },
      { type: 'hash', value: '1a2b3c4d5e6f7890abcdef1234567890abcdef1234' }
    ]

    # Test with different node limits
    limited_context = @manager.expand_context_with_entities(entities, 2, 5)
    expanded_context = @manager.expand_context_with_entities(entities, 2, 50)

    assert_instance_of Array, limited_context
    assert_instance_of Array, expanded_context
  end

  def test_caching_functionality
    @manager.setup

    # Add some knowledge first
    @manager.add_knowledge_triplet("TestEntity", "RELATES_TO", "TestTarget")

    query = "What is TestEntity?"

    # First call
    context1 = @manager.get_context_for_query(query)

    # Second call (should use cache)
    context2 = @manager.get_context_for_query(query)

    assert_equal context1, context2, "Cached results should be identical"
  end

  def test_error_handling_edge_cases
    @manager.setup

    # Test with malformed triplet data
    result = @manager.add_knowledge_triplet("", "", "")
    refute result, "Should handle empty triplet data gracefully"

    # Test with very long entity names
    long_name = "A" * 1000
    result = @manager.add_knowledge_triplet(long_name, "RELATES_TO", "Target")
    assert result, "Should handle long entity names"
  end

  def test_concurrent_operations
    @manager.setup

    threads = []
    results = []

    # Concurrent triplet addition
    5.times do |i|
      threads << Thread.new do
        result = @manager.add_knowledge_triplet("Concurrent_#{i}", "RELATES_TO", "Target_#{i}")
        results << result
      end
    end

    threads.each(&:join)

    # All operations should succeed
    assert_equal 5, results.length
    results.each { |result| assert result }
  end

  def test_knowledge_graph_persistence
    @manager.setup

    # Add knowledge
    @manager.add_knowledge_triplet("PersistentEntity", "RELATES_TO", "PersistentTarget")

    # Verify it exists
    related = @manager.find_related_entities("PersistentEntity")
    refute_empty related, "Knowledge should persist"

    # Cleanup and verify it's gone
    @manager.cleanup

    # Recreate manager and verify knowledge is gone
    new_manager = CAGManager.new(@knowledge_graph_config, @entity_extractor_config, @cag_config)
    new_manager.setup

    related = new_manager.find_related_entities("PersistentEntity")
    assert_empty related, "Knowledge should be cleared after cleanup"
  end

  def test_entity_type_filtering
    @manager.setup

    test_text = "IP: 192.168.1.100, URL: http://test.com, Hash: abc123, Port: 8080"

    # Test with all types
    all_entities = @manager.extract_entities(test_text)
    assert all_entities.length >= 4, "Should extract multiple entity types"

    # Test with specific type
    ip_only = @manager.extract_entities(test_text, ['ip_address'])
    assert_equal 1, ip_only.length
    assert_equal 'ip_address', ip_only.first[:type]
  end

  def test_cross_reference_functionality
    @manager.setup

    # Create interconnected knowledge
    @manager.add_knowledge_triplet("Mimikatz", "IS_TYPE", "Malware")
    @manager.add_knowledge_triplet("Mimikatz", "TARGETS", "Windows")
    @manager.add_knowledge_triplet("Windows", "HAS_VULNERABILITY", "CVE-2021-1234")

    # Query should find cross-referenced information
    context = @manager.get_context_for_query("Mimikatz vulnerabilities")
    refute_nil context
    refute_empty context
  end
end
