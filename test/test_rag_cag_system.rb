require './rag_cag_manager.rb'
require './print.rb'
require 'minitest/autorun'

# Test suite for RAG + CAG system
class TestRAGCAGSystem < Minitest::Test
  def setup
    # Configuration for testing
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
        max_results: 3,
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
      cache_ttl: 1800, # 30 minutes
      auto_initialization: true
    }

    @manager = nil
  end

  def test_manager_initialization
    puts "Testing RAG + CAG Manager initialization..."

    @manager = RAGCAGManager.new(@rag_config, @cag_config, @unified_config)
    result = @manager.initialize

    assert result, "RAG + CAG Manager should initialize successfully"
    assert @manager.initialized?, "Manager should be marked as initialized"

    puts "✓ RAG + CAG Manager initialization successful"
  end

  def test_knowledge_base_initialization
    puts "Testing knowledge base initialization..."

    @manager = RAGCAGManager.new(@rag_config, @cag_config, @unified_config)
    @manager.initialize

    result = @manager.initialize_knowledge_base
    assert result, "Knowledge base should initialize successfully"

    puts "✓ Knowledge base initialization successful"
  end

  def test_enhanced_context_retrieval
    puts "Testing enhanced context retrieval..."

    @manager = RAGCAGManager.new(@rag_config, @cag_config, @unified_config)
    @manager.initialize
    @manager.initialize_knowledge_base

    # Test queries
    test_queries = [
      "What is credential dumping?",
      "Tell me about phishing attacks",
      "How do I mitigate ransomware?",
      "What tools are used for network scanning?"
    ]

    test_queries.each do |query|
      context = @manager.get_enhanced_context(query)
      assert context, "Should return enhanced context for query: #{query}"
      assert context.length > 0, "Context should not be empty for query: #{query}"

      puts "✓ Retrieved context for query: #{query}"
      puts "  Context length: #{context.length} characters"
    end
  end

  def test_entity_extraction
    puts "Testing entity extraction..."

    @manager = RAGCAGManager.new(@rag_config, @cag_config, @unified_config)
    @manager.initialize

    test_messages = [
      "The attack came from 192.168.1.100 using http://malicious.com/malware.exe",
      "Found file suspicious.dll with hash 1a2b3c4d5e6f7890abcdef1234567890abcdef1234",
      "Connected to server on port 4444",
      "Email received from john.doe@example.com"
    ]

    test_messages.each do |message|
      entities = @manager.extract_entities(message)
      assert entities.is_a?(Array), "Should return array of entities for message: #{message}"

      puts "✓ Extracted #{entities.length} entities from: #{message}"
      entities.each { |entity| puts "  - #{entity[:type]}: #{entity[:value]}" }
    end
  end

  def test_related_entities
    puts "Testing related entity retrieval..."

    @manager = RAGCAGManager.new(@rag_config, @cag_config, @unified_config)
    @manager.initialize
    @manager.initialize_knowledge_base

    test_entities = [
      "Mimikatz",
      "Emotet",
      "Phishing",
      "Ransomware"
    ]

    test_entities.each do |entity|
      related_entities = @manager.find_related_entities(entity)
      assert related_entities.is_a?(Array), "Should return array of related entities for: #{entity}"

      puts "✓ Found #{related_entities.length} related entities for: #{entity}"
      related_entities.each do |related|
        puts "  - #{related[:labels] && related[:labels].join(', ')}: #{related[:properties] && related[:properties]['name']}"
      end
    end
  end

  def test_custom_knowledge_addition
    puts "Testing custom knowledge addition..."

    @manager = RAGCAGManager.new(@rag_config, @cag_config, @unified_config)
    @manager.initialize

    # Custom documents
    custom_documents = [
      {
        id: 'custom_doc_1',
        content: 'Custom vulnerability description: Cross-Site Scripting (XSS) is a type of injection attack.',
        metadata: { source: 'custom', type: 'vulnerability' }
      },
      {
        id: 'custom_doc_2',
        content: 'Custom mitigation: Use input validation and output encoding to prevent XSS.',
        metadata: { source: 'custom', type: 'mitigation' }
      }
    ]

    # Custom triplets
    custom_triplets = [
      {
        subject: 'Cross-Site Scripting',
        relationship: 'IS_TYPE',
        object: 'Vulnerability',
        properties: { severity: 'High' }
      },
      {
        subject: 'Cross-Site Scripting',
        relationship: 'MITIGATED_BY',
        object: 'Input Validation',
        properties: { effectiveness: 'High' }
      }
    ]

    result = @manager.add_custom_knowledge('custom_collection', custom_documents, custom_triplets)
    assert result, "Should successfully add custom knowledge"

    # Test retrieval of custom knowledge
    context = @manager.get_enhanced_context('What is XSS?', { custom_collection: 'custom_collection' })
    assert context, "Should retrieve context from custom knowledge"
    assert context.include?('Cross-Site Scripting'), "Context should include custom knowledge"

    puts "✓ Custom knowledge addition and retrieval successful"
  end

  def test_caching_functionality
    puts "Testing caching functionality..."

    @manager = RAGCAGManager.new(@rag_config, @cag_config, @unified_config.merge({
      enable_caching: true,
      cache_ttl: 60
    }))
    @manager.initialize
    @manager.initialize_knowledge_base

    query = "What is credential dumping?"

    # First call - should cache the result
    context1 = @manager.get_enhanced_context(query)
    assert context1, "First call should return context"

    # Second call - should use cache
    context2 = @manager.get_enhanced_context(query)
    assert context2, "Second call should return cached context"
    assert_equal context1, context2, "Cached context should match first call"

    puts "✓ Caching functionality working correctly"
  end

  def test_connection_tests
    puts "Testing connection functionality..."

    @manager = RAGCAGManager.new(@rag_config, @cag_config, @unified_config)
    @manager.initialize

    # Test individual connections
    rag_ok = @manager.instance_variable_get(:@rag_manager).test_connection if @manager.instance_variable_get(:@rag_manager)
    cag_ok = @manager.instance_variable_get(:@cag_manager).test_connection if @manager.instance_variable_get(:@cag_manager)

    puts "RAG Connection: #{rag_ok ? 'OK' : 'FAILED'}"
    puts "CAG Connection: #{cag_ok ? 'OK' : 'FAILED'}"

    # Test unified connection test
    unified_ok = @manager.test_connections
    assert unified_ok, "Unified connection test should pass"

    puts "✓ Connection tests completed"
  end

  def test_retrieval_stats
    puts "Testing retrieval statistics..."

    @manager = RAGCAGManager.new(@rag_config, @cag_config, @unified_config)
    @manager.initialize
    @manager.initialize_knowledge_base

    stats = @manager.get_retrieval_stats
    assert stats.is_a?(Hash), "Should return hash of statistics"
    assert stats.key?(:initialized), "Stats should include initialization status"
    assert stats.key?(:rag_enabled), "Stats should indicate RAG status"
    assert stats.key?(:cag_enabled), "Stats should indicate CAG status"

    puts "✓ Retrieval statistics working:"
    puts "  - Initialized: #{stats[:initialized]}"
    puts "  - RAG Enabled: #{stats[:rag_enabled]}"
    puts "  - CAG Enabled: #{stats[:cag_enabled]}"
    puts "  - Cache Size: #{stats[:cache_size]}"
  end

  def test_cleanup_functionality
    puts "Testing cleanup functionality..."

    @manager = RAGCAGManager.new(@rag_config, @cag_config, @unified_config)
    @manager.initialize

    # Perform some operations to create state
    @manager.initialize_knowledge_base
    @manager.get_enhanced_context("test query")

    # Cleanup
    @manager.cleanup

    # Check that cleanup worked
    rag_manager = @manager.instance_variable_get(:@rag_manager)
    cag_manager = @manager.instance_variable_get(:@cag_manager)

    assert !@manager.initialized?, "Manager should not be initialized after cleanup"

    puts "✓ Cleanup functionality working correctly"
  end

  def test_error_handling
    puts "Testing error handling..."

    # Test with invalid configuration
    invalid_config = @rag_config.dup
    invalid_config[:vector_db][:provider] = 'invalid_provider'

    @manager = RAGCAGManager.new(invalid_config, @cag_config, @unified_config)

    # Should handle initialization gracefully
    result = @manager.initialize
    assert !result, "Should fail gracefully with invalid configuration"

    # Test with empty query
    if @manager.initialized?
      empty_context = @manager.get_enhanced_context("")
      assert empty_context.nil? || empty_context.empty?, "Should handle empty query gracefully"
    end

    puts "✓ Error handling working correctly"
  end

  def teardown
    if @manager
      @manager.cleanup
    end
  end
end

# Run tests if this file is executed directly
if __FILE__ == $0
  puts "Starting RAG + CAG System Tests"
  puts "=" * 50

  # Run all tests
  Minitest.run

  puts "\n" + "=" * 50
  puts "RAG + CAG System Tests completed"
end
