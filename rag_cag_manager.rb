require './rag/rag_manager.rb'
require './cag/cag_manager.rb'
require './knowledge_bases/mitre_attack_knowledge.rb'
require './knowledge_bases/knowledge_source_manager.rb'
require './print.rb'

# Unified RAG + CAG Manager for integrated knowledge retrieval and context-aware generation
class RAGCAGManager
  # Public accessors
  attr_reader :initialized, :cag_manager, :rag_manager, :knowledge_source_manager
  def initialize(rag_config, cag_config, unified_config = {})
    @rag_config = rag_config
    @cag_config = cag_config
    @unified_config = {
      enable_rag: unified_config[:enable_rag] || true,
      enable_cag: unified_config[:enable_cag] || true,
      rag_weight: unified_config[:rag_weight] || 0.6,
      cag_weight: unified_config[:cag_weight] || 0.4,
      max_context_length: unified_config[:max_context_length] || 4000,
      knowledge_base_name: unified_config[:knowledge_base_name] || 'cybersecurity',
      enable_caching: unified_config[:enable_caching] || false,
      cache_ttl: unified_config[:cache_ttl] || 3600, # 1 hour
      auto_initialization: unified_config[:auto_initialization] || true,
      enable_knowledge_sources: unified_config[:enable_knowledge_sources] || true,
      knowledge_sources_config: unified_config[:knowledge_sources_config] || []
    }

    @cache = {}
    @cache_timestamps = {}
    @initialized = false
    @rag_manager = nil
    @cag_manager = nil
    @knowledge_source_manager = nil
  end

  def setup
    return if @initialized

    Print.info "Initializing RAG + CAG Manager..."

    success = true

    # Initialize RAG if enabled
    if @unified_config[:enable_rag]
      Print.info "Initializing RAG component..."
      @rag_manager = RAGManager.new(
        @rag_config[:vector_db],
        @rag_config[:embedding_service],
        @rag_config[:rag_settings]
      )

      unless @rag_manager.setup
        Print.err "Failed to initialize RAG Manager"
        success = false
      end
    end

    # Initialize CAG if enabled
    if @unified_config[:enable_cag]
      Print.info "Initializing CAG component..."
      @cag_manager = CAGManager.new(
        @cag_config[:knowledge_graph],
        @cag_config[:entity_extractor],
        @cag_config[:cag_settings]
      )

      unless @cag_manager.setup
        Print.err "Failed to initialize CAG Manager"
        success = false
      end
    end

    # Initialize knowledge source manager if enabled
    if @unified_config[:enable_knowledge_sources]
      Print.info "Initializing Knowledge Source Manager..."
      @knowledge_source_manager = KnowledgeSourceManager.new(@unified_config)

      sources_config = @unified_config[:knowledge_sources_config] || default_knowledge_sources_config
      unless @knowledge_source_manager.initialize_sources(sources_config)
        Print.err "Failed to initialize Knowledge Source Manager"
        success = false
      end
    end

    if success
      @initialized = true
      Print.info "RAG + CAG Manager initialized successfully"

      # Auto-initialize knowledge base if configured
      if @unified_config[:auto_initialization]
        initialize_knowledge_base
      end
    else
      Print.err "RAG + CAG Manager initialization failed"
    end

    success
  end

  def initialize_knowledge_base
    unless @initialized
      setup unless setup
      return false
    end

    Print.info "Initializing knowledge base: #{@unified_config[:knowledge_base_name]}"

    success = true

    # Load knowledge from all sources
    if @unified_config[:enable_knowledge_sources] && @knowledge_source_manager
      Print.info "Loading knowledge from all sources..."
      unless @knowledge_source_manager.load_all_knowledge
        Print.err "Failed to load knowledge from sources"
        success = false
      end

      # Get documents and triplets from all sources
      all_rag_documents = @knowledge_source_manager.get_all_rag_documents
      all_cag_triplets = @knowledge_source_manager.get_all_cag_triplets

      Print.info "Retrieved #{all_rag_documents.length} RAG documents and #{all_cag_triplets.length} CAG triplets from sources"

      # Initialize RAG knowledge base
      if @unified_config[:enable_rag] && @rag_manager && !all_rag_documents.empty?
        unless @rag_manager.add_knowledge_base(@unified_config[:knowledge_base_name], all_rag_documents)
          Print.err "Failed to add RAG knowledge base"
          success = false
        end
      end

      # Initialize CAG knowledge base
      if @unified_config[:enable_cag] && @cag_manager && !all_cag_triplets.empty?
        unless @cag_manager.create_knowledge_base_from_triplets(all_cag_triplets)
          Print.err "Failed to create CAG knowledge base"
          success = false
        end
      end
    else
      # Fallback to legacy MITRE Attack knowledge only
      Print.info "Using legacy MITRE Attack knowledge base..."

      # Initialize RAG knowledge base
      if @unified_config[:enable_rag] && @rag_manager
        Print.info "Loading RAG documents..."
        rag_documents = MITREAttackKnowledge.to_rag_documents
        Print.info "Generated #{rag_documents.length} RAG documents"

        unless @rag_manager.add_knowledge_base(@unified_config[:knowledge_base_name], rag_documents)
          Print.err "Failed to add RAG knowledge base"
          success = false
        end
      end

      # Initialize CAG knowledge base
      if @unified_config[:enable_cag] && @cag_manager
        Print.info "Loading CAG knowledge triplets..."
        cag_triplets = MITREAttackKnowledge.to_cag_triplets
        Print.info "Generated #{cag_triplets.length} CAG knowledge triplets"

        unless @cag_manager.create_knowledge_base_from_triplets(cag_triplets)
          Print.err "Failed to create CAG knowledge base"
          success = false
        end
      end
    end

    if success
      Print.info "Knowledge base initialization completed successfully"
    else
      Print.err "Knowledge base initialization failed"
    end

    success
  end

  def get_enhanced_context(query, context_options = {})
    unless @initialized
      setup unless setup
      return nil
    end

    # Check cache first
    cache_key = "enhanced_#{query.hash}"
    if @unified_config[:enable_caching] && cached_response_valid?(cache_key)
      Print.debug "Using cached enhanced context for query: #{query[0..50]}..."
      return @cache[cache_key]
    end

    context_options = {
      max_rag_results: context_options[:max_rag_results] || 5,
      max_cag_depth: context_options[:max_cag_depth] || 2,
      max_cag_nodes: context_options[:max_cag_nodes] || 10,
      include_rag_context: context_options[:include_rag_context] || true,
      include_cag_context: context_options[:include_cag_context] || true,
      custom_collection: context_options[:custom_collection] || @unified_config[:knowledge_base_name]
    }.merge(context_options)

    Print.info "Getting enhanced context for query: #{query[0..50]}..."

    begin
      rag_context = ""
      cag_context = ""

      # Get RAG context
      if @unified_config[:enable_rag] && context_options[:include_rag_context] && @rag_manager
        Print.info "Retrieving RAG context..."
        rag_context = @rag_manager.retrieve_relevant_context(
          query,
          context_options[:custom_collection],
          context_options[:max_rag_results]
        ) || ""
        Print.info "RAG context length: #{rag_context.length} characters"
      end

      # Get CAG context
      if @unified_config[:enable_cag] && context_options[:include_cag_context] && @cag_manager
        Print.info "Retrieving CAG context..."
        cag_context = @cag_manager.get_context_for_query(
          query,
          context_options[:max_cag_depth],
          context_options[:max_cag_nodes]
        ) || ""
        Print.info "CAG context length: #{cag_context.length} characters"
      end

      # Combine contexts
      enhanced_context = combine_contexts(rag_context, cag_context, query)

      # Cache the result if enabled
      if @unified_config[:enable_caching]
        @cache[cache_key] = enhanced_context
        @cache_timestamps[cache_key] = Time.now
        cleanup_cache
      end

      Print.info "Enhanced context generated with total length: #{enhanced_context.length} characters"
      enhanced_context
    rescue => e
      Print.err "Error getting enhanced context: #{e.message}"
      Print.err e.backtrace.inspect
      nil
    end
  end

  def add_custom_knowledge(collection_name, documents, triplets = [])
    unless @initialized
      setup unless setup
      return false
    end

    Print.info "Adding custom knowledge to collection: #{collection_name}"

    success = true

    # Add RAG documents
    if @unified_config[:enable_rag] && @rag_manager && !documents.empty?
      Print.info "Adding #{documents.length} custom RAG documents..."
      unless @rag_manager.add_knowledge_base(collection_name, documents)
        Print.err "Failed to add custom RAG documents"
        success = false
      end
    end

    # Add CAG triplets
    if @unified_config[:enable_cag] && @cag_manager && !triplets.empty?
      Print.info "Adding #{triplets.length} custom CAG triplets..."
      unless @cag_manager.create_knowledge_base_from_triplets(triplets)
        Print.err "Failed to add custom CAG triplets"
        success = false
      end
    end

    # Clear cache for this collection
    if @unified_config[:enable_caching]
      @cache.keys.each do |key|
        @cache.delete(key) if key.include?(collection_name)
        @cache_timestamps.delete(key)
      end
    end

    if success
      Print.info "Custom knowledge added successfully to collection: #{collection_name}"
    else
      Print.err "Failed to add custom knowledge to collection: #{collection_name}"
    end

    success
  end

  def extract_entities(query, entity_types = nil)
    unless @initialized
      setup unless setup
      return []
    end

    return [] unless @unified_config[:enable_cag] && @cag_manager

    Print.info "Extracting entities from query..."
    entities = @cag_manager.extract_entities(query, entity_types)
    Print.info "Extracted #{entities.length} entities"
    entities
  end

  def find_related_entities(entity_name, relationship_type = nil, depth = 1)
    unless @initialized
      setup unless setup
      return []
    end

    return [] unless @unified_config[:enable_cag] && @cag_manager

    Print.info "Finding related entities for: #{entity_name}"
    related_entities = @cag_manager.find_related_entities(entity_name, relationship_type, depth)
    Print.info "Found #{related_entities.length} related entities"
    related_entities
  end

  def get_retrieval_stats
    return {} unless @initialized

    stats = {
      unified_config: @unified_config,
      initialized: @initialized,
      cache_size: @cache.length,
      rag_enabled: @unified_config[:enable_rag] && @rag_manager,
      cag_enabled: @unified_config[:enable_cag] && @cag_manager
    }

    # Add RAG stats
    if @rag_manager
      stats[:rag_collections] = @rag_manager.list_collections
      stats[:rag_connected] = @rag_manager.test_connection
    end

    # Add CAG stats
    if @cag_manager
      knowledge_graph = @cag_manager.instance_variable_get(:@knowledge_graph)
      stats[:cag_graph_stats] = knowledge_graph.get_graph_stats if knowledge_graph.respond_to?(:get_graph_stats)
      stats[:cag_connected] = @cag_manager.test_connection
    end

    stats
  end

  def test_connections
    Print.info "Testing RAG + CAG Manager connections..."

    rag_ok = true
    cag_ok = true

    if @unified_config[:enable_rag] && @rag_manager
      rag_ok = @rag_manager.test_connection
      Print.info "RAG Connection: #{rag_ok ? 'OK' : 'FAILED'}"
    end

    if @unified_config[:enable_cag] && @cag_manager
      cag_ok = @cag_manager.test_connection
      Print.info "CAG Connection: #{cag_ok ? 'OK' : 'FAILED'}"
    end

    overall_ok = rag_ok && cag_ok
    Print.info "RAG + CAG Manager: #{overall_ok ? 'OK' : 'FAILED'}"

    overall_ok
  end

  def cleanup
    Print.info "Cleaning up RAG + CAG Manager..."

    if @rag_manager
      @rag_manager.cleanup
    end

    if @cag_manager
      @cag_manager.cleanup
    end

    if @knowledge_source_manager
      @knowledge_source_manager.cleanup
    end

    @cache.clear
    @cache_timestamps.clear
    @initialized = false

    Print.info "RAG + CAG Manager cleanup completed"
  end

  def reload_knowledge_base
    Print.info "Reloading knowledge base..."

    # Delete existing collections and knowledge
    if @rag_manager
      @rag_manager.delete_collection(@unified_config[:knowledge_base_name])
    end

    # Clear cache
    @cache.clear
    @cache_timestamps.clear

    # Reinitialize knowledge base
    initialize_knowledge_base
  end

  private

  def combine_contexts(rag_context, cag_context, query)
    combined_parts = []

    # Add weighted sections based on configuration
    if @unified_config[:enable_rag] && !rag_context.strip.empty?
      combined_parts << "=== RETRIEVED DOCUMENTS ==="
      combined_parts << rag_context
      combined_parts << ""
    end

    if @unified_config[:enable_cag] && !cag_context.strip.empty?
      combined_parts << "=== KNOWLEDGE GRAPH CONTEXT ==="
      combined_parts << cag_context
      combined_parts << ""
    end

    # Add query context
    combined_parts << "=== ORIGINAL QUERY ==="
    combined_parts << query
    combined_parts << ""

    # Add context usage instructions
    combined_parts << "=== CONTEXT USAGE INSTRUCTIONS ==="
    combined_parts << "Use the above retrieved documents and knowledge graph context to provide an informed response. "
    combined_parts << "Prioritize information from retrieved documents for factual accuracy. "
    combined_parts << "Use knowledge graph relationships to provide additional context and connections. "
    combined_parts << "If the retrieved information is incomplete or ambiguous, acknowledge this limitation. "
    combined_parts << "Always cite specific attack patterns, techniques, or mitigation strategies when relevant."

    # Join and truncate if necessary
    full_context = combined_parts.join("\n")

    if full_context.length > @unified_config[:max_context_length]
      Print.warn "Context exceeds maximum length (#{full_context.length} > #{@unified_config[:max_context_length]}), truncating..."
      # Truncate intelligently - try to preserve complete sections
      truncated = truncate_intelligently(full_context, @unified_config[:max_context_length])
      Print.info "Truncated context length: #{truncated.length}"
      truncated
    else
      full_context
    end
  end

  def truncate_intelligently(text, max_length)
    return text if text.length <= max_length

    # Try to preserve complete sections by looking for section boundaries
    sections = text.split(/(?=== )/)
    result = ""

    sections.each do |section|
      if (result + section).length <= max_length
        result += section
      else
        # If adding this section would exceed limit, see if we can add a partial version
        remaining_space = max_length - result.length
        if remaining_space > 100 # Don't add very small fragments
          result += section[0, remaining_space - 3] + "..."
        end
        break
      end
    end

    result
  end

  def cached_response_valid?(cache_key)
    return false unless @cache.key?(cache_key) && @cache_timestamps.key?(cache_key)

    timestamp = @cache_timestamps[cache_key]
    current_time = Time.now

    (current_time - timestamp).to_i <= @unified_config[:cache_ttl]
  end

  def cleanup_cache
    return unless @unified_config[:enable_caching]

    current_time = Time.now
    expired_keys = []

    @cache_timestamps.each do |key, timestamp|
      if (current_time - timestamp).to_i > @unified_config[:cache_ttl]
        expired_keys << key
      end
    end

    expired_keys.each do |key|
      @cache.delete(key)
      @cache_timestamps.delete(key)
    end

    if expired_keys.any?
      Print.debug "Cleaned up #{expired_keys.length} expired cache entries"
    end
  end

  private

  def default_knowledge_sources_config
    [
      {
        type: 'mitre_attack',
        name: 'mitre_attack',
        enabled: true,
        description: 'MITRE ATT&CK framework knowledge base',
        priority: 1
      }
    ]
  end

  def add_man_page_to_sources(man_name, section = nil, collection_name = 'default_man_pages')
    return false unless @unified_config[:enable_knowledge_sources] && @knowledge_source_manager

    # Find or create man pages source
    man_source = @knowledge_source_manager.instance_variable_get(:@sources)['man_pages']
    unless man_source
      # Add man pages source
      man_source_config = {
        type: 'man_pages',
        name: 'man_pages',
        enabled: true,
        description: 'Unix/Linux man pages',
        priority: 2,
        man_pages: []  # Start empty
      }

      unless @knowledge_source_manager.add_knowledge_source(man_source_config)
        Print.err "Failed to add man pages knowledge source"
        return false
      end

      man_source = @knowledge_source_manager.instance_variable_get(:@sources)['man_pages']
    end

    # Add the man page
    man_source.add_man_page(man_name, section, collection_name)
  end

  def add_markdown_file_to_sources(file_path, collection_name = 'default_markdown_files')
    return false unless @unified_config[:enable_knowledge_sources] && @knowledge_source_manager

    # Find or create markdown files source
    md_source = @knowledge_source_manager.instance_variable_get(:@sources)['markdown_files']
    unless md_source
      # Add markdown files source
      md_source_config = {
        type: 'markdown_files',
        name: 'markdown_files',
        enabled: true,
        description: 'Markdown documentation files',
        priority: 3,
        markdown_files: []  # Start empty
      }

      unless @knowledge_source_manager.add_knowledge_source(md_source_config)
        Print.err "Failed to add markdown files knowledge source"
        return false
      end

      md_source = @knowledge_source_manager.instance_variable_get(:@sources)['markdown_files']
    end

    # Add the markdown file
    md_source.add_markdown_file(file_path, collection_name)
  end

  def get_knowledge_source_stats
    return {} unless @unified_config[:enable_knowledge_sources] && @knowledge_source_manager

    @knowledge_source_manager.get_source_statistics
  end
end
