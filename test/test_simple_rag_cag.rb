#!/usr/bin/env ruby

# Simple test to verify RAG + CAG system works
require 'minitest/autorun'
require_relative '../rag_cag_manager'
require_relative '../print'

class TestSimpleRAGCAG < Minitest::Test
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
        max_context_nodes: 10,
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

    @manager = nil
  end

  def teardown
    if @manager
      @manager.cleanup
    end
  end

  def test_manager_creation
    puts "Testing RAG + CAG Manager creation..."

    @manager = RAGCAGManager.new(@rag_config, @cag_config, @unified_config)
    assert_instance_of RAGCAGManager, @manager
    refute @manager.initialized?, "Manager should not be initialized initially"

    puts "✓ RAG + CAG Manager creation successful"
  end

  def test_manager_setup
    puts "Testing RAG + CAG Manager setup..."

    @manager = RAGCAGManager.new(@rag_config, @cag_config, @unified_config)
    result = @manager.setup

    assert result, "RAG + CAG Manager should setup successfully"
    assert @manager.initialized?, "Manager should be marked as initialized"

    puts "✓ RAG + CAG Manager setup successful"
  end

  def test_entity_extraction
    puts "Testing entity extraction..."

    @manager = RAGCAGManager.new(@rag_config, @cag_config, @unified_config)
    @manager.setup

    test_text = "Attack from 192.168.1.100 using http://malicious.com/malware.exe"
    entities = @manager.extract_entities(test_text)

    assert entities.is_a?(Array), "Should return array of entities"
    refute_empty entities, "Should extract entities from test text"

    puts "Extracted #{entities.length} entities:"
    entities.each { |entity| puts "  - #{entity[:type]}: #{entity[:value]}" }

    puts "✓ Entity extraction successful"
  end

  def test_knowledge_triplet_addition
    puts "Testing knowledge triplet addition..."

    @manager = RAGCAGManager.new(@rag_config, @cag_config, @unified_config)
    @manager.setup

    result = @manager.add_knowledge_triplet("Mimikatz", "IS_TYPE", "Malware")
    assert result, "Should successfully add knowledge triplet"

    puts "✓ Knowledge triplet addition successful"
  end

  def test_context_retrieval
    puts "Testing context retrieval..."

    @manager = RAGCAGManager.new(@rag_config, @cag_config, @unified_config)
    @manager.setup

    # Add some test knowledge
    @manager.add_knowledge_triplet("Mimikatz", "IS_TYPE", "Malware")
    @manager.add_knowledge_triplet("Phishing", "IS_TYPE", "Attack")

    query = "What is Mimikatz?"
    context = @manager.get_enhanced_context(query)

    assert context, "Should retrieve context for query"
    assert context.length > 0, "Context should not be empty"

    puts "Retrieved context (#{context.length} chars) for query: #{query}"
    puts "✓ Context retrieval successful"
  end

  def test_cleanup
    puts "Testing cleanup functionality..."

    @manager = RAGCAGManager.new(@rag_config, @cag_config, @unified_config)
    @manager.setup
    @manager.add_knowledge_triplet("Test", "RELATES_TO", "Subject")

    assert @manager.initialized?, "Should be initialized before cleanup"

    @manager.cleanup

    refute @manager.initialized?, "Should not be initialized after cleanup"

    puts "✓ Cleanup functionality successful"
  end

  def test_connection_status
    puts "Testing connection status..."

    @manager = RAGCAGManager.new(@rag_config, @cag_config, @unified_config)

    # Test before setup
    refute @manager.initialized?, "Should not be initialized before setup"

    # Test after setup
    @manager.setup
    assert @manager.initialized?, "Should be initialized after setup"

    # Test connection method
    connection_ok = @manager.test_connections
    assert connection_ok, "Connection test should pass"

    puts "✓ Connection status test successful"
  end
end

# Run tests if this file is executed directly
if __FILE__ == $0
  puts "Starting Simple RAG + CAG Tests"
  puts "=" * 40

  # Run all tests
  Minitest.run

  puts "\n" + "=" * 40
  puts "Simple RAG + CAG Tests completed"
end
