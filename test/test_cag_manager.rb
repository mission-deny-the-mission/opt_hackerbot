require_relative 'test_helper.rb'
require_relative '../cag_manager.rb'

class TestCAGManager < Minitest::Test
  def setup
    @config = {
      knowledge_base_name: 'test_kb',
      enable_cag: true,
      max_context_length: 8000,
      preload_limit: 10,
      auto_initialization: false,
      enable_knowledge_sources: true,
      knowledge_sources_config: [
        {
          type: 'mitre_attack',
          name: 'test_mitre',
          enabled: true,
          priority: 1
        }
      ]
    }
    
    @cag_config = {
      vector_db: { provider: 'test' },
      embedding_service: { provider: 'test' },
      rag_settings: { max_results: 5 }
    }
  end

  def test_cag_manager_initialization
    cag_manager = CAGManager.new(@cag_config, @config)
    
    refute_nil cag_manager
    assert_equal false, cag_manager.initialized
    assert_equal 'test_kb', cag_manager.instance_variable_get(:@config)[:knowledge_base_name]
  end

  def test_cag_manager_setup_without_knowledge_sources
    config = @config.dup
    config[:enable_knowledge_sources] = false
    
    cag_manager = CAGManager.new(@cag_config, config)
    result = cag_manager.setup
    
    assert_equal true, result
    assert_equal true, cag_manager.initialized
  end

  def test_get_cached_context_without_preload
    config = @config.dup
    config[:enable_knowledge_sources] = false
    config[:auto_initialization] = false
    config[:knowledge_sources_config] = []
    cag_manager = CAGManager.new(@cag_config, config)
    cag_manager.setup
    
    context = cag_manager.get_cached_context("test query")
    
    refute_nil context
    assert_equal "test query", context[:original_query]
    assert_equal "test query", context[:combined_context]
    assert_equal true, context[:preloaded]
    assert context[:sources].empty?
  end

  def test_get_cached_context_with_preload
    cag_manager = CAGManager.new(@cag_config, @config)
    cag_manager.setup
    
    context = cag_manager.get_cached_context("test query")
    
    refute_nil context
    assert_equal "test query", context[:original_query]
    assert context[:combined_context].include?("test query")
    assert context[:combined_context].include?("Preloaded Knowledge Context:")
    assert_equal true, context[:preloaded]
    refute context[:sources].empty?
  end

  def test_get_status
    cag_manager = CAGManager.new(@cag_config, @config)
    status = cag_manager.get_status
    
    refute_nil status
    assert_equal false, status[:initialized]
    assert_equal false, status[:preloaded_available]
    assert_equal 0, status[:document_count]
    assert_equal 0, status[:estimated_tokens]
    assert_equal 0, status[:cache_size]
  end

  def test_invalidate_cache
    cag_manager = CAGManager.new(@cag_config, @config)
    cag_manager.setup
    
    # Add something to cache
    cag_manager.get_cached_context("test query")
    
    # Check cache has content
    cache_size_before = cag_manager.get_status[:cache_size]
    assert cache_size_before > 0
    
    # Invalidate cache
    cag_manager.invalidate_cache
    
    # Check cache is empty
    cache_size_after = cag_manager.get_status[:cache_size]
    assert_equal 0, cache_size_after
  end

  def test_build_preloaded_context
    cag_manager = CAGManager.new(@cag_config, @config)
    
    # Mock RAG documents
    rag_docs = [
      {
        content: "This is test document 1 content",
        metadata: { source: "test_source_1", priority: 2 }
      },
      {
        content: "This is test document 2 content",
        metadata: { source: "test_source_2", priority: 1 }
      }
    ]
    
    # Call the private method through send
    context = cag_manager.send(:build_preloaded_context, rag_docs)
    
    refute_nil context
    assert context[:context_text].include?("Document 1")
    assert context[:context_text].include?("Document 2")
    assert_equal 2, context[:document_count]
    assert context[:total_tokens] > 0
    # Sources should contain both test sources in some order
    assert_equal 2, context[:sources].length
    assert context[:sources].include?("test_source_1")
    assert context[:sources].include?("test_source_2")
  end

  def test_context_compression
    cag_manager = CAGManager.new(@cag_config, @config)
    
    # Create a long context that needs compression
    long_context = "=== Document 1 ===\n"
    (1..30).each { |i| long_context += "Line #{i} of document 1 content\n" }
    long_context += "\n=== Document 2 ===\n"
    (1..30).each { |i| long_context += "Line #{i} of document 2 content\n" }
    
    compressed = cag_manager.send(:compress_context, long_context)
    
    assert compressed.length < long_context.length
    assert compressed.include?("=== Document 1 ===")
    assert compressed.include?("=== Document 2 ===")
    assert compressed.include?("[... content truncated for brevity ...]")
  end

  def test_cached_response_valid
    cag_manager = CAGManager.new(@cag_config, @config)
    
    # Test with non-existent cache key
    assert_equal false, cag_manager.send(:cached_response_valid?, "nonexistent")
    
    # Test with existing but expired cache
    cache_key = "test_key"
    cag_manager.instance_variable_get(:@context_cache)[cache_key] = { test: "data" }
    cag_manager.instance_variable_get(:@cache_timestamps)[cache_key] = Time.now - 3700 # Over 1 hour ago
    
    assert_equal false, cag_manager.send(:cached_response_valid?, cache_key)
    
    # Test with existing and valid cache
    cag_manager.instance_variable_get(:@cache_timestamps)[cache_key] = Time.now - 1800 # 30 minutes ago
    assert_equal true, cag_manager.send(:cached_response_valid?, cache_key)
  end

  def test_default_knowledge_sources_config
    cag_manager = CAGManager.new(@cag_config, @config)
    
    default_config = cag_manager.send(:default_knowledge_sources_config)
    
    refute_nil default_config
    assert default_config.is_a?(Array)
    assert default_config.length > 0
    assert_equal 'mitre_attack', default_config.first[:type]
    assert_equal true, default_config.first[:enabled]
  end
end