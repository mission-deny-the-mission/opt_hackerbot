require './knowledge_bases/knowledge_source_manager.rb'
require './print.rb'

# Cache-Augmented Generation (CAG) Manager
# Preloads documents into LLM context for immediate access without retrieval
class CAGManager
  attr_reader :initialized, :knowledge_source_manager

  def initialize(cag_config, config = {})
    @cag_config = cag_config
    @config = {
      enable_cag: config.key?(:enable_cag) ? config[:enable_cag] : true,
      max_context_length: config[:max_context_length] || 16000,
      knowledge_base_name: config[:knowledge_base_name] || 'cybersecurity',
      enable_caching: config[:enable_caching] || true,
      cache_ttl: config[:cache_ttl] || 3600, # 1 hour
      auto_initialization: config[:auto_initialization] || true,
      enable_knowledge_sources: config[:enable_knowledge_sources] || true,
      knowledge_sources_config: config[:knowledge_sources_config] || [],
      preload_limit: config[:preload_limit] || 50, # Max documents to preload
      context_compression: config[:context_compression] || true
    }

    @preloaded_context = nil
    @context_cache = {}
    @cache_timestamps = {}
    @initialized = false
    @knowledge_source_manager = nil

    # Debug logging for config
    Print.info "CAGManager initialized with config:"
    Print.info "  knowledge_base_name: #{@config[:knowledge_base_name].inspect}"
    Print.info "  enable_cag: #{@config[:enable_cag].inspect}"
    Print.info "  preload_limit: #{@config[:preload_limit].inspect}"
  end

  def setup
    return if @initialized

    Print.info "Initializing CAG Manager..."

    success = true

    # Initialize knowledge source manager if enabled
    if @config[:enable_knowledge_sources]
      Print.info "Initializing Knowledge Source Manager for CAG..."
      @knowledge_source_manager = KnowledgeSourceManager.new(@config)

      sources_config = @config[:knowledge_sources_config] || default_knowledge_sources_config
      unless @knowledge_source_manager.initialize_sources(sources_config)
        Print.err "Failed to initialize Knowledge Source Manager for CAG"
        success = false
      end
    end

    if success
      @initialized = true
      Print.info "CAG Manager initialized successfully"

      # Auto-initialize knowledge base if configured and knowledge sources enabled
      if @config[:auto_initialization] && @config[:enable_knowledge_sources]
        preload_knowledge_context
      end
    else
      Print.err "CAG Manager initialization failed"
    end

    success
  end

  def preload_knowledge_context
    unless @initialized
      setup unless setup
      return false
    end

    Print.info "Preloading knowledge context for CAG system..."

    success = true

    # Load knowledge from all sources
    if @config[:enable_knowledge_sources] && @knowledge_source_manager
      Print.info "Loading knowledge from all sources for preloading..."
      unless @knowledge_source_manager.load_all_knowledge
        Print.err "Failed to load knowledge from sources for CAG"
        success = false
        return success
      end

      # Get documents from all sources
      all_rag_documents = @knowledge_source_manager.get_all_rag_documents
      Print.info "Retrieved #{all_rag_documents.length} documents for CAG preloading"

      # Preload documents into context
      if !all_rag_documents.empty?
        @preloaded_context = build_preloaded_context(all_rag_documents)
        Print.info "Built preloaded context with #{@preloaded_context[:total_tokens]} estimated tokens"
      else
        Print.warn "No documents available for CAG preloading"
        success = false
      end
    else
      Print.warn "Knowledge sources disabled - no context to preload for CAG"
      success = false
    end

    if success
      Print.info "Knowledge context preloading completed successfully"
    else
      Print.err "Knowledge context preloading failed"
    end

    success
  end

  def get_cached_context(query, context_options = {})
    unless @initialized
      setup unless setup
      return nil
    end

    # Check cache first
    cache_key = "cag_#{query.hash}"
    if @config[:enable_caching] && cached_response_valid?(cache_key)
      Print.debug "Using cached CAG context for query: #{query[0..50]}..."
      return @context_cache[cache_key]
    end

    context_options = {
      max_context_length: context_options[:max_context_length] || @config[:max_context_length],
      include_source_info: context_options[:include_source_info] || true
    }.merge(context_options)

    enhanced_context = {
      original_query: query,
      cag_context: nil,
      combined_context: query,
      sources: [],
      timestamp: Time.now,
      preloaded: true
    }

    # Use preloaded context if available
    if @preloaded_context
      Print.debug "Using preloaded CAG context for query: #{query[0..50]}..."
      
      enhanced_context[:cag_context] = @preloaded_context
      enhanced_context[:sources] = @preloaded_context[:sources] || []

      # Combine with original query
      context_text = @preloaded_context[:context_text] || ""
      
      # Truncate if needed to fit context window
      if context_text.length > context_options[:max_context_length] - query.length - 100
        truncate_length = context_options[:max_context_length] - query.length - 100
        context_text = context_text[0..truncate_length] + "...\n[Context truncated for length]"
        Print.debug "Truncated preloaded context to fit context window"
      end

      enhanced_context[:combined_context] = "#{query}\n\nPreloaded Knowledge Context:\n#{context_text}"

      Print.debug "Using preloaded context with #{@preloaded_context[:document_count]} documents"
    else
      Print.debug "No preloaded context available for CAG"
    end

    # Cache result if enabled
    if @config[:enable_caching]
      @context_cache[cache_key] = enhanced_context
      @cache_timestamps[cache_key] = Time.now
    end

    enhanced_context
  end

  def invalidate_cache
    @context_cache.clear
    @cache_timestamps.clear
    @preloaded_context = nil
    Print.info "CAG cache invalidated"
  end

  def refresh_knowledge_context
    invalidate_cache
    preload_knowledge_context
  end

  def get_status
    {
      initialized: @initialized,
      preloaded_available: !@preloaded_context.nil?,
      document_count: @preloaded_context ? @preloaded_context[:document_count] : 0,
      estimated_tokens: @preloaded_context ? @preloaded_context[:total_tokens] : 0,
      cache_size: @context_cache.size,
      sources_available: @knowledge_source_manager ? (@knowledge_source_manager.respond_to?(:get_initialized_sources) ? @knowledge_source_manager.get_initialized_sources.length : 0) : 0
    }
  end

  private

  def build_preloaded_context(rag_documents)
    Print.info "Building preloaded context from #{rag_documents.length} documents..."
    
    # Sort documents by priority or relevance if available
    sorted_docs = rag_documents.sort_by { |doc| -(doc[:metadata]&.dig(:priority) || 0) }
    
    # Limit documents to prevent context overflow
    limited_docs = sorted_docs.first(@config[:preload_limit])
    
    context_parts = []
    sources = []
    total_tokens = 0
    
    limited_docs.each_with_index do |doc, index|
      content = doc[:content] || doc['content'] || ""
      next if content.empty?
      
      # Add document with separator
      doc_header = "=== Document #{index + 1}"
      if doc[:metadata] && doc[:metadata][:source]
        doc_header += " (#{doc[:metadata][:source]})"
        sources << doc[:metadata][:source] unless sources.include?(doc[:metadata][:source])
      end
      doc_header += " ==="
      
      doc_content = "#{doc_header}\n#{content}\n"
      context_parts << doc_content
      
      # Rough token estimation (4 chars per token average)
      total_tokens += doc_content.length / 4
      
      # Stop if approaching context limit
      if total_tokens > (@config[:max_context_length] * 0.8)
        Print.debug "Stopping document preloading at #{index + 1} docs due to context size"
        break
      end
    end
    
    context_text = context_parts.join("\n")
    
    # Compress context if enabled and too large
    if @config[:context_compression] && context_text.length > @config[:max_context_length]
      context_text = compress_context(context_text)
      Print.debug "Applied context compression"
    end
    
    {
      context_text: context_text,
      document_count: context_parts.length,
      total_tokens: total_tokens,
      sources: sources.uniq,
      created_at: Time.now
    }
  end

  def compress_context(context_text)
    # Simple compression: keep headers and first part of each section
    lines = context_text.split("\n")
    compressed_lines = []
    in_document = false
    current_doc_lines = 0
    max_lines_per_doc = 20
    
    lines.each do |line|
      if line.start_with?("=== Document")
        compressed_lines << line
        in_document = true
        current_doc_lines = 0
      elsif in_document
        if current_doc_lines < max_lines_per_doc
          compressed_lines << line
          current_doc_lines += 1
        elsif current_doc_lines == max_lines_per_doc
          compressed_lines << "[... content truncated for brevity ...]"
          current_doc_lines += 1
        end
        # Skip remaining lines for this document
      else
        compressed_lines << line
      end
    end
    
    compressed_lines.join("\n")
  end

  def cached_response_valid?(cache_key)
    return false unless @context_cache.key?(cache_key)
    return false unless @cache_timestamps.key?(cache_key)
    
    Time.now - @cache_timestamps[cache_key] < @config[:cache_ttl]
  end

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
end