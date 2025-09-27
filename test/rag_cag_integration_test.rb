require_relative './test_helper'
require_relative './rag_cag_manager'
require_relative './print'

# Comprehensive integration tests for RAG + CAG system
class TestRAGCAGIntegration < Minitest::Test
  def setup
    @rag_config = {
      vector_db: {
        provider: 'chromadb',
        host: 'localhost',
        port: 8000
      },
      embedding_service: {
        provider: 'openai',
        api_key: 'test_api_key',
        model: 'text-embedding-ada-002'
      },
      rag_settings: {
        max_results: 5,
        similarity_threshold: 0.5,
        enable_caching: true
      }
    }

    @cag_config = {
      knowledge_graph: {
        provider: 'in_memory'
      },
      entity_extractor: {
        provider: 'rule_based'
      },
      cag_settings: {
        max_context_depth: 2,
        max_context_nodes: 15,
        enable_caching: true
      }
    }

    @unified_config = {
      enable_rag: true,
      enable_cag: true,
      rag_weight: 0.6,
      cag_weight: 0.4,
      max_context_length: 2000,
      enable_caching: true,
      cache_ttl: 1800,
      auto_initialization: true
    }

    @manager = RAGCAGManager.new(@rag_config, @cag_config, @unified_config)
  end

  def teardown
    @manager.cleanup if @manager
  end

  def test_system_initialization
    puts "Testing RAG + CAG system initialization..."

    result = @manager.initialize
    assert result, "RAG + CAG system should initialize successfully"
    assert @manager.initialized?, "System should be marked as initialized"

    puts "✓ System initialization successful"
  end

  def test_knowledge_base_setup
    puts "Testing knowledge base setup..."

    @manager.initialize
    result = @manager.initialize_knowledge_base
    assert result, "Knowledge base should initialize successfully"

    puts "✓ Knowledge base setup successful"
  end

  def test_hybrid_context_retrieval
    puts "Testing hybrid context retrieval..."

    @manager.initialize
    @manager.initialize_knowledge_base

    # Test cybersecurity-related queries
    test_queries = [
      "What is credential dumping and how does Mimikatz work?",
      "Explain phishing attacks and their prevention techniques",
      "What are the common indicators of ransomware attacks?",
      "How do attackers perform lateral movement in networks?",
      "What is the MITRE ATT&CK framework?"
    ]

    test_queries.each do |query|
      puts "  Testing query: #{query}"

      # Get enhanced context
      context = @manager.get_enhanced_context(query)
      assert context, "Should return enhanced context for query: #{query}"
      assert context.length > 0, "Context should not be empty for query: #{query}"

      # Extract entities from query
      entities = @manager.extract_entities(query)
      puts "    Extracted #{entities.length} entities"
      entities.each { |entity| puts "      - #{entity[:type]}: #{entity[:value]}" }

      # Get related entities
      entities.each do |entity|
        related = @manager.find_related_entities(entity[:value])
        puts "    Found #{related.length} related entities for #{entity[:value]}"
      end

      puts "    Context length: #{context.length} characters"
      puts "  ✓ Query processed successfully"
    end

    puts "✓ Hybrid context retrieval successful"
  end

  def test_entity_extraction_and_analysis
    puts "Testing entity extraction and analysis..."

    @manager.initialize

    test_messages = [
      "Attack originated from 192.168.1.100 using http://malicious.com/backdoor.exe",
      "Suspicious file detected: mimikatz.exe with hash 1a2b3c4d5e6f7890abcdef1234567890abcdef1234",
      "C2 server communication on port 4444 to attacker@example.com",
      "Multiple IPs involved: 10.0.0.1, 172.16.0.1, 192.168.1.1",
      "Downloaded payload from https://evil-site.com/payload.dll"
    ]

    test_messages.each do |message|
      puts "  Analyzing message: #{message}"

      entities = @manager.extract_entities(message)
      assert entities.is_a?(Array), "Should return array of entities"

      puts "    Extracted #{entities.length} entities:"
      entities.each do |entity|
        puts "      - #{entity[:type]}: #{entity[:value]} (position: #{entity[:position]})"
      end

      # Test entity-based context expansion
      if entities.any?
        context_nodes = @manager.instance_variable_get(:@cag_manager).expand_context_with_entities(entities)
        puts "    Expanded to #{context_nodes.length} context nodes"
      end

      puts "  ✓ Message analyzed successfully"
    end

    puts "✓ Entity extraction and analysis successful"
  end

  def test_knowledge_graph_operations
    puts "Testing knowledge graph operations..."

    @manager.initialize

    # Test knowledge triplet addition
    test_triplets = [
      { subject: "Mimikatz", relationship: "IS_TYPE", object: "Malware", properties: { severity: "High" } },
      { subject: "Mimikatz", relationship: "USES_TECHNIQUE", object: "Credential Dumping", properties: { technique_id: "T1003.001" } },
      { subject: "Credential Dumping", relationship: "MITIGATED_BY", object: "Credential Guard", properties: { effectiveness: "High" } },
      { subject: "Phishing", relationship: "IS_TYPE", object: "Social Engineering", properties: { severity: "Medium" } },
      { subject: "Phishing", relationship: "DELIVERS_VIA", object: "Email", properties: { common: true } }
    ]

    test_triplets.each do |triplet|
      result = @manager.add_knowledge_triplet(triplet[:subject], triplet[:relationship], triplet[:object], triplet[:properties])
      assert result, "Should successfully add triplet: #{triplet[:subject]} -> #{triplet[:object]}"
    end

    # Test related entity finding
    test_entities = ["Mimikatz", "Phishing", "Credential Dumping"]
    test_entities.each do |entity|
      related = @manager.find_related_entities(entity)
      puts "  Found #{related.length} related entities for #{entity}:"
      related.each do |rel|
        puts "    - #{rel[:properties] && rel[:properties]['name']}"
      end
    end

    puts "✓ Knowledge graph operations successful"
  end

  def test_document_knowledge_integration
    puts "Testing document and knowledge integration..."

    @manager.initialize

    # Add document knowledge
    documents = [
      {
        id: 'mitre_attack_doc',
        content: 'MITRE ATT&CK is a globally-accessible knowledge base of adversary tactics and techniques based on real-world observations. The ATT&CK knowledge base is used as a foundation for the development of specific threat models and methodologies in the private sector, in government, and in the cybersecurity product and service community.',
        metadata: { source: 'MITRE', type: 'framework', category: 'cybersecurity' }
      },
      {
        id: 'credential_dumping_doc',
        content: 'Credential dumping is the process of obtaining account login and password information, normally in the form of a hash or clear text password, from the operating system and software. Credential dumping techniques are used to obtain credentials from memory, file systems, or databases.',
        metadata: { source: 'security_guide', type: 'technique', category: 'credential_access' }
      },
      {
        id: 'phishing_doc',
        content: 'Phishing is a type of social engineering attack often used to steal user data, including login credentials and credit card numbers. It occurs when an attacker, masquerading as a trusted entity, dupes a victim into opening an email, instant message, or text message.',
        metadata: { source: 'security_guide', type: 'attack', category: 'social_engineering' }
      }
    ]

    # Add knowledge triplets
    triplets = [
      { subject: "MITRE ATT&CK", relationship: "IS_TYPE", object: "Framework", properties: { domain: "cybersecurity" } },
      { subject: "Credential Dumping", relationship: "HAS_TECHNIQUE_ID", object: "T1003", properties: { tactic: "Credential Access" } },
      { subject: "Phishing", relationship: "HAS_TECHNIQUE_ID", object: "T1566", properties: { tactic: "Initial Access" } }
    ]

    result = @manager.add_custom_knowledge('cybersecurity_kb', documents, triplets)
    assert result, "Should successfully add integrated knowledge"

    # Test retrieval with context
    query = "What techniques are used for credential access according to MITRE ATT&CK?"
    context = @manager.get_enhanced_context(query, { custom_collection: 'cybersecurity_kb' })

    assert context, "Should retrieve integrated context"
    assert context.length > 0, "Context should not be empty"

    puts "  Retrieved integrated context (#{context.length} chars)"
    puts "  ✓ Document and knowledge integration successful"

    puts "✓ Document and knowledge integration successful"
  end

  def test_caching_functionality
    puts "Testing caching functionality..."

    @manager.initialize
    @manager.initialize_knowledge_base

    query = "What is the MITRE ATT&CK framework?"

    # First call - should cache the result
    context1 = @manager.get_enhanced_context(query)
    assert context1, "First call should return context"

    # Second call - should use cache
    context2 = @manager.get_enhanced_context(query)
    assert context2, "Second call should return cached context"
    assert_equal context1, context2, "Cached context should match first call"

    # Test entity caching
    test_text = "Attack from 192.168.1.100 using mimikatz.exe"
    entities1 = @manager.extract_entities(test_text)
    entities2 = @manager.extract_entities(test_text)

    assert_equal entities1.length, entities2.length, "Entity extraction should be consistent"

    puts "✓ Caching functionality working correctly"
  end

  def test_performance_under_load
    puts "Testing performance under load..."

    @manager.initialize
    @manager.initialize_knowledge_base

    # Test multiple concurrent queries
    queries = [
      "What is ransomware?",
      "How do firewalls work?",
      "What is penetration testing?",
      "Explain zero-day vulnerabilities",
      "What is incident response?",
      "How does encryption work?",
      "What is network segmentation?",
      "Explain multi-factor authentication",
      "What is a SIEM system?",
      "How do DDoS attacks work?"
    ]

    start_time = Time.now
    results = []

    # Process queries in parallel simulation
    queries.each do |query|
      context = @manager.get_enhanced_context(query)
      entities = @manager.extract_entities(query)
      results << { query: query, context_length: context ? context.length : 0, entity_count: entities.length }
    end

    end_time = Time.now
    total_time = end_time - start_time

    puts "  Processed #{queries.length} queries in #{total_time.round(2)} seconds"
    puts "  Average time per query: #{(total_time / queries.length).round(3)} seconds"

    results.each do |result|
      puts "    - #{result[:query]}: #{result[:context_length]} chars, #{result[:entity_count]} entities"
    end

    assert total_time < 30, "Should process all queries within 30 seconds"
    assert results.all? { |r| r[:context_length] > 0 }, "All queries should return context"

    puts "✓ Performance test passed"
  end

  def test_error_handling_and_recovery
    puts "Testing error handling and recovery..."

    # Test with invalid configurations
    invalid_rag_config = @rag_config.dup
    invalid_rag_config[:vector_db][:provider] = 'invalid_provider'

    begin
      invalid_manager = RAGCAGManager.new(invalid_rag_config, @cag_config, @unified_config)
      result = invalid_manager.initialize
      refute result, "Should handle invalid configuration gracefully"
    rescue => e
      puts "  ✓ Invalid configuration handled: #{e.message}"
    end

    # Test with empty queries
    @manager.initialize
    empty_context = @manager.get_enhanced_context("")
    assert empty_context.nil? || empty_context.empty?, "Should handle empty query gracefully"

    # Test with malformed text
    malformed_text = "Special chars: \x00\x01\x02 malformed text"
    entities = @manager.extract_entities(malformed_text)
    assert entities.is_a?(Array), "Should handle malformed text gracefully"

    puts "✓ Error handling and recovery working correctly"
  end

  def test_system_statistics_and_monitoring
    puts "Testing system statistics and monitoring..."

    @manager.initialize
    @manager.initialize_knowledge_base

    # Perform some operations to generate statistics
    @manager.get_enhanced_context("What is cybersecurity?")
    @manager.extract_entities("Test with IP 192.168.1.1 and URL http://test.com")
    @manager.add_knowledge_triplet("Test", "RELATES_TO", "Subject")

    stats = @manager.get_retrieval_stats
    assert stats.is_a?(Hash), "Should return hash of statistics"
    assert stats.key?(:initialized), "Stats should include initialization status"
    assert stats.key?(:rag_enabled), "Stats should indicate RAG status"
    assert stats.key?(:cag_enabled), "Stats should indicate CAG status"
    assert stats.key?(:cache_size), "Stats should include cache size"

    puts "  System statistics:"
    puts "    - Initialized: #{stats[:initialized]}"
    puts "    - RAG Enabled: #{stats[:rag_enabled]}"
    puts "    - CAG Enabled: #{stats[:cag_enabled]}"
    puts "    - Cache Size: #{stats[:cache_size]}"
    puts "    - Last Updated: #{stats[:last_updated]}"

    # Test connection status
    connection_ok = @manager.test_connections
    assert connection_ok, "Connection tests should pass"

    puts "  ✓ System statistics and monitoring working"

    puts "✓ System statistics and monitoring successful"
  end

  def test_cleanup_and_resource_management
    puts "Testing cleanup and resource management..."

    @manager.initialize
    @manager.initialize_knowledge_base

    # Perform operations to create state
    @manager.get_enhanced_context("Test query")
    @manager.extract_entities("Test text")
    @manager.add_knowledge_triplet("Test", "RELATES_TO", "Subject")

    # Verify system is active
    assert @manager.initialized?, "System should be initialized before cleanup"

    # Get pre-cleanup stats
    pre_cleanup_stats = @manager.get_retrieval_stats

    # Perform cleanup
    @manager.cleanup

    # Verify cleanup worked
    refute @manager.initialized?, "System should not be initialized after cleanup"

    # Verify resources are freed
    post_cleanup_stats = @manager.get_retrieval_stats
    assert post_cleanup_stats[:cache_size] < pre_cleanup_stats[:cache_size], "Cache should be cleared after cleanup"

    puts "  ✓ Cleanup completed successfully"
    puts "  ✓ Resources properly managed"

    puts "✓ Cleanup and resource management successful"
  end

  def test_end_to_end_cybersecurity_scenario
    puts "Testing end-to-end cybersecurity scenario..."

    @manager.initialize

    # Setup cybersecurity knowledge base
    scenario_documents = [
      {
        id: 'apt28_doc',
        content: 'APT28 is a Russian threat group that has been attributed to the GRU. They are known for targeting government, military, and security organizations. APT28 commonly uses spear-phishing campaigns and zero-day exploits in their attacks.',
        metadata: { source: 'threat_intel', type: 'threat_actor', category: 'apt' }
      },
      {
        id: 'spear_phishing_doc',
        content: 'Spear phishing is a targeted email attack that aims to steal sensitive information or install malware. Unlike regular phishing, spear phishing targets specific individuals or organizations using personalized information.',
        metadata: { source: 'attack_guide', type: 'technique', category: 'social_engineering' }
      },
      {
        id: 'zero_day_doc',
        content: 'A zero-day vulnerability is a software vulnerability that is unknown to the vendor and for which no patch or fix is available. Attackers exploit zero-day vulnerabilities before developers have a chance to address them.',
        metadata: { source: 'vulnerability_db', type: 'vulnerability', category: 'exploit' }
      }
    ]

    scenario_triplets = [
      { subject: "APT28", relationship: "IS_TYPE", object: "Threat Actor", properties: { country: "Russia", sophistication: "High" } },
      { subject: "APT28", relationship: "USES_TECHNIQUE", object: "Spear Phishing", properties: { frequency: "High" } },
      { subject: "APT28", relationship: "EXPLOITS", object: "Zero-day", properties: { capability: "Advanced" } },
      { subject: "Spear Phishing", relationship: "IS_TYPE", object: "Social Engineering", properties: { delivery_method: "Email" } },
      { subject: "Zero-day", relationship: "REQUIRES", object: "Patch Management", properties: { mitigation: "Critical" } }
    ]

    # Add scenario knowledge
    result = @manager.add_custom_knowledge('apt_scenario', scenario_documents, scenario_triplets)
    assert result, "Should successfully add scenario knowledge"

    # Test scenario queries
    scenario_queries = [
      "What techniques does APT28 use in their attacks?",
      "How can organizations defend against spear phishing?",
      "What is the relationship between zero-day vulnerabilities and patch management?",
      "Describe the threat profile of APT28",
      "What are the mitigation strategies for advanced persistent threats?"
    ]

    scenario_queries.each do |query|
      puts "  Processing scenario query: #{query}"

      # Get enhanced context
      context = @manager.get_enhanced_context(query, { custom_collection: 'apt_scenario' })
      assert context, "Should retrieve scenario context"
      assert context.length > 0, "Context should not be empty"

      # Extract entities
      entities = @manager.extract_entities(query)
      puts "    Found #{entities.length} entities in query"

      # Get related entities
      entities.each do |entity|
        related = @manager.find_related_entities(entity[:value])
        puts "    #{entity[:value]} has #{related.length} related entities"
      end

      puts "    Context length: #{context.length} characters"
      puts "  ✓ Query processed successfully"
    end

    puts "✓ End-to-end cybersecurity scenario completed successfully"
  end

  def test_comprehensive_system_validation
    puts "Testing comprehensive system validation..."

    @manager.initialize

    # Test all major system components
    validation_tests = [
      {
        name: "RAG Component",
        test: -> { @manager.instance_variable_get(:@rag_manager).test_connection }
      },
      {
        name: "CAG Component",
        test: -> { @manager.instance_variable_get(:@cag_manager).test_connection }
      },
      {
        name: "Entity Extraction",
        test: -> {
          entities = @manager.extract_entities("Test IP 192.168.1.1")
          entities.is_a?(Array) && !entities.empty?
        }
      },
      {
        name: "Knowledge Triplet Addition",
        test: -> { @manager.add_knowledge_triplet("Test", "RELATES_TO", "Subject") }
      },
      {
        name: "Context Retrieval",
        test: -> {
          context = @manager.get_enhanced_context("test query")
          context && context.length > 0
        }
      },
      {
        name: "Related Entity Finding",
        test: -> {
          @manager.add_knowledge_triplet("TestEntity", "RELATES_TO", "Related")
          related = @manager.find_related_entities("TestEntity")
          related.is_a?(Array)
        }
      }
    ]

    passed_tests = 0
    total_tests = validation_tests.length

    validation_tests.each do |test_case|
      puts "  Testing #{test_case[:name]}..."
      begin
        result = test_case[:test].call
        if result
          puts "    ✓ #{test_case[:name]} passed"
          passed_tests += 1
        else
          puts "    ✗ #{test_case[:name]} failed"
        end
      rescue => e
        puts "    ✗ #{test_case[:name]} error: #{e.message}"
      end
    end

    puts "  Validation results: #{passed_tests}/#{total_tests} tests passed"
    assert_equal total_tests, passed_tests, "All validation tests should pass"

    puts "✓ Comprehensive system validation completed"
  end
end

# Run tests if this file is executed directly
if __FILE__ == $0
  puts "Starting RAG + CAG Integration Tests"
  puts "=" * 60

  # Run all tests
  Minitest.run

  puts "\n" + "=" * 60
  puts "RAG + CAG Integration Tests completed"
end
