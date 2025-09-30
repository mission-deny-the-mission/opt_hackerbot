#!/usr/bin/env ruby

# RAG + CAG Offline Configuration Manager
# This file provides comprehensive offline configuration support for the RAG + CAG system
# when running without internet connectivity

require 'fileutils'
require 'json'
require './print.rb'

class OfflineConfigurationManager
  DEFAULT_OFFLINE_CONFIG_PATH = File.join(Dir.pwd, 'config', 'offline_config.json')
  DEFAULT_KNOWLEDGE_BASE_PATH = File.join(Dir.pwd, 'knowledge_bases', 'offline')
  DEFAULT_EMBEDDING_CACHE_PATH = File.join(Dir.pwd, 'cache', 'embeddings')
  DEFAULT_GRAPH_CACHE_PATH = File.join(Dir.pwd, 'cache', 'graph')

  def initialize(config_path = nil)
    @config_path = config_path || DEFAULT_OFFLINE_CONFIG_PATH
    @config = load_default_configuration
    @knowledge_base_path = DEFAULT_KNOWLEDGE_BASE_PATH
    @embedding_cache_path = DEFAULT_EMBEDDING_CACHE_PATH
    @graph_cache_path = DEFAULT_GRAPH_CACHE_PATH
    @offline_mode = false
    @knowledge_loaded = false
  end

  def load_default_configuration
    {
      version: "1.0.0",
      offline_mode: {
        enabled: true,
        auto_detect: true,
        fallback_to_offline: true
      },
      rag: {
        offline_mode: true,  # Default to offline mode
        vector_db: {
          provider: "chromadb",
          storage_path: DEFAULT_KNOWLEDGE_BASE_PATH,
          persist_embeddings: true,
          compression_enabled: true
        },
        embedding_service: {
          provider: "ollama",
          model: "nomic-embed-text",
          local_model_path: nil,
          cache_embeddings: true,
          cache_path: DEFAULT_EMBEDDING_CACHE_PATH
        },
        document_preprocessing: {
          chunk_size: 1000,
          chunk_overlap: 200,
          normalize_text: true,
          remove_stopwords: false
        }
      },
      cag: {
        offline_mode: true,  # Default to offline mode
        knowledge_graph: {
          provider: "in_memory",
          storage_path: DEFAULT_KNOWLEDGE_BASE_PATH,
          persist_graph: true,
          load_from_file: true
        },
        entity_extractor: {
          provider: "rule_based",
          custom_patterns: nil,
          cache_entities: true
        },
        graph_traversal: {
          max_depth: 3,
          max_nodes: 50,
          enable_caching: true
        }
      },
      knowledge_bases: {
        auto_load: true,
        preload_on_startup: true,
        update_strategy: "manual",  # "manual", "auto", "scheduled"
        sources: [
          {
            name: "mitre_attack",
            type: "builtin",
            enabled: true,
            version: "latest"
          },
          {
            name: "cybersecurity_essentials",
            type: "custom",
            enabled: true,
            path: "knowledge_bases/cybersecurity_essentials.json"
          }
        ]
      },
      caching: {
        enabled: true,
        max_size_mb: 1024,  # 1GB
        ttl_seconds: 86400,  # 24 hours
        persist_to_disk: true,
        cache_path: File.join(Dir.pwd, 'cache', 'offline')
      },
      performance: {
        enable_memory_optimization: true,
        max_memory_usage_mb: 2048,  # 2GB
        enable_streaming: true,
        batch_size: 50
      },
      monitoring: {
        log_performance_metrics: true,
        track_cache_hits: true,
        enable_offline_diagnostics: true
      }
    }
  end

  def load_configuration(config_path = nil)
    config_file = config_path || @config_path

    begin
      if File.exist?(config_file)
        Print.info "Loading offline configuration from: #{config_file}"
        file_content = File.read(config_file)
        loaded_config = JSON.parse(file_content)

        # Merge with default configuration to ensure all fields exist
        @config = deep_merge(@config, loaded_config)
        Print.info "Offline configuration loaded successfully"
      else
        Print.warn "Offline configuration file not found: #{config_file}"
        Print.info "Using default configuration"
        save_default_configuration
      end
    rescue => e
      Print.err "Failed to load offline configuration: #{e.message}"
      Print.info "Using default configuration"
    end

    @config
  end

  def save_default_configuration
    config_dir = File.dirname(DEFAULT_OFFLINE_CONFIG_PATH)
    FileUtils.mkdir_p(config_dir) unless File.exist?(config_dir)

    begin
      File.write(DEFAULT_OFFLINE_CONFIG_PATH, JSON.pretty_generate(@config))
      Print.info "Default offline configuration saved to: #{DEFAULT_OFFLINE_CONFIG_PATH}"
    rescue => e
      Print.err "Failed to save default configuration: #{e.message}"
    end
  end

  def enable_offline_mode
    Print.info "Enabling offline RAG + CAG mode..."

    @offline_mode = true
    @config[:offline_mode][:enabled] = true

    # Setup offline directories
    setup_offline_directories

    # Load offline knowledge bases
    load_offline_knowledge_bases if @config[:knowledge_bases][:auto_load]

    Print.info "Offline mode enabled successfully"
  end

  def disable_offline_mode
    Print.info "Disabling offline mode..."
    @offline_mode = false
    @config[:offline_mode][:enabled] = false
    Print.info "Offline mode disabled"
  end

  def offline_mode?
    @offline_mode || @config[:offline_mode][:enabled]
  end

  def detect_connectivity
    # Simple connectivity check - try to resolve common hosts
    test_hosts = ['8.8.8.8', '1.1.1.1', 'google.com']

    test_hosts.each do |host|
      begin
        require 'socket'
        socket = TCPSocket.new(host, 53, connect_timeout: 2)
        socket.close
        return true  # Connected
      rescue
        next
      end
    end

    false  # Offline
  end

  def auto_detect_and_configure
    return unless @config[:offline_mode][:auto_detect] && !@offline_mode

    Print.info "Auto-detecting connectivity..."

    if detect_connectivity
      Print.info "Online connectivity detected"
    else
      Print.info "No internet connectivity detected, enabling offline mode"
      enable_offline_mode if @config[:offline_mode][:fallback_to_offline]
    end
  end

  def get_rag_config
    rag_config = @config[:rag].dup

    # Configure for offline operation
    if offline_mode?
      rag_config[:vector_db][:offline_mode] = true
      rag_config[:embedding_service][:offline_mode] = true

      # Update paths with offline-specific paths
      rag_config[:vector_db][:storage_path] = File.join(@knowledge_base_path, 'vector_db')
      rag_config[:embedding_service][:cache_path] = @embedding_cache_path
    end

    rag_config
  end

  def get_cag_config
    cag_config = @config[:cag].dup

    # Configure for offline operation
    if offline_mode?
      cag_config[:knowledge_graph][:offline_mode] = true
      cag_config[:knowledge_graph][:storage_path] = File.join(@knowledge_base_path, 'graph')

      # Ensure entity extractor uses offline patterns
      cag_config[:entity_extractor][:offline_mode] = true
    end

    cag_config
  end

  def get_unified_config
    unified_config = {
      enable_rag: @config[:rag][:offline_mode],
      enable_cag: @config[:cag][:offline_mode],
      rag_weight: 0.6,
      cag_weight: 0.4,
      max_context_length: 4000,
      enable_caching: @config[:caching][:enabled],
      cache_ttl: @config[:caching][:ttl_seconds],
      auto_initialization: true,
      offline_mode: offline_mode?
    }

    unified_config
  end

  def setup_offline_directories
    directories = [
      @knowledge_base_path,
      @embedding_cache_path,
      @graph_cache_path,
      File.join(@knowledge_base_path, 'vector_db'),
      File.join(@knowledge_base_path, 'graph'),
      File.join(@knowledge_base_path, 'documents'),
      File.dirname(@config_path)
    ]

    directories.each do |dir|
      FileUtils.mkdir_p(dir) unless File.exist?(dir)
      Print.debug "Created directory: #{dir}"
    end

    Print.info "Offline directories setup completed"
  end

  def load_offline_knowledge_bases
    return if @knowledge_loaded

    Print.info "Loading offline knowledge bases..."

    success_count = 0
    total_count = @config[:knowledge_bases][:sources].length

    @config[:knowledge_bases][:sources].each do |source|
      next unless source[:enabled]

      Print.info "Loading knowledge base: #{source[:name]} (#{source[:type]})"

      begin
        case source[:type]
        when 'builtin'
          success = load_builtin_knowledge_base(source)
        when 'custom'
          success = load_custom_knowledge_base(source)
        else
          Print.warn "Unknown knowledge base type: #{source[:type]}"
          success = false
        end

        if success
          success_count += 1
          Print.info "✓ Successfully loaded: #{source[:name]}"
        else
          Print.err "✗ Failed to load: #{source[:name]}"
        end
      rescue => e
        Print.err "Error loading knowledge base #{source[:name]}: #{e.message}"
      end
    end

    @knowledge_loaded = true
    Print.info "Knowledge base loading completed: #{success_count}/#{total_count} loaded successfully"
  end

  def load_builtin_knowledge_base(source)
    require_relative './knowledge_bases/mitre_attack_knowledge.rb'

    knowledge_base_path = File.join(@knowledge_base_path, 'builtin', source[:name])
    FileUtils.mkdir_p(knowledge_base_path) unless File.exist?(knowledge_base_path)

    # Generate and save RAG documents
    rag_documents = MITREAttackKnowledge.to_rag_documents
    documents_file = File.join(knowledge_base_path, 'rag_documents.json')
    File.write(documents_file, JSON.pretty_generate(rag_documents))

    # Generate and save CAG triplets
    cag_triplets = MITREAttackKnowledge.to_cag_triplets
    triplets_file = File.join(knowledge_base_path, 'cag_triplets.json')
    File.write(triplets_file, JSON.pretty_generate(cag_triplets))

    # Save metadata
    metadata = {
      name: source[:name],
      type: source[:type],
      version: source[:version],
      documents_count: rag_documents.length,
      triplets_count: cag_triplets.length,
      created_at: Time.now.iso8601,
      loaded_at: Time.now.iso8601
    }

    metadata_file = File.join(knowledge_base_path, 'metadata.json')
    File.write(metadata_file, JSON.pretty_generate(metadata))

    Print.info "Built-in knowledge base '#{source[:name]}' saved to: #{knowledge_base_path}"
    true
  rescue => e
    Print.err "Failed to load built-in knowledge base #{source[:name]}: #{e.message}"
    false
  end

  def load_custom_knowledge_base(source)
    return unless source[:path]

    knowledge_path = source[:path]
    unless File.exist?(knowledge_path)
      Print.err "Custom knowledge base file not found: #{knowledge_path}"
      return false
    end

    begin
      knowledge_data = JSON.parse(File.read(knowledge_path))

      # Validate knowledge base structure
      if knowledge_data['documents'] || knowledge_data['triplets']
        # Save to offline location
        offline_path = File.join(@knowledge_base_path, 'custom', source[:name])
        FileUtils.mkdir_p(offline_path) unless File.exist?(offline_path)

        File.write(File.join(offline_path, 'knowledge.json'), JSON.pretty_generate(knowledge_data))

        Print.info "Custom knowledge base '#{source[:name]}' loaded from: #{knowledge_path}"
        true
      else
        Print.err "Invalid custom knowledge base format: #{source[:name]}"
        false
      end
    rescue => e
      Print.err "Failed to load custom knowledge base #{source[:name]}: #{e.message}"
      false
    end
  end

  def preload_embeddings
    return unless offline_mode? && @config[:rag][:embedding_service][:cache_embeddings]

    Print.info "Preloading embeddings for offline operation..."

    # This would typically load pre-computed embeddings from disk
    # For the implementation, this would be integrated with the specific embedding service
    embedding_cache_file = File.join(@embedding_cache_path, 'embeddings_cache.json')

    if File.exist?(embedding_cache_file)
      begin
        cache_data = JSON.parse(File.read(embedding_cache_file))
        Print.info "Loaded #{cache_data.length} cached embeddings"
      rescue => e
        Print.err "Failed to load embedding cache: #{e.message}"
      end
    else
      Print.info "No embedding cache found, will generate on demand"
    end
  end

  def get_offline_statistics
    return {} unless offline_mode?

    stats = {
      offline_mode: true,
      knowledge_bases_loaded: @knowledge_loaded,
      directories: {
        knowledge_base: @knowledge_base_path,
        embedding_cache: @embedding_cache_path,
        graph_cache: @graph_cache_path
      },
      knowledge_base_stats: {},
      cache_stats: {}
    }

    # Collect knowledge base statistics
    if File.exist?(@knowledge_base_path)
      builtin_path = File.join(@knowledge_base_path, 'builtin')
      custom_path = File.join(@knowledge_base_path, 'custom')

      stats[:knowledge_base_stats][:builtin] = collect_directory_stats(builtin_path)
      stats[:knowledge_base_stats][:custom] = collect_directory_stats(custom_path)
    end

    # Collect cache statistics
    cache_dirs = [@embedding_cache_path, @graph_cache_path]
    cache_dirs.each do |cache_dir|
      cache_name = File.basename(cache_dir)
      stats[:cache_stats][cache_name] = collect_directory_stats(cache_dir)
    end

    stats
  end

  def validate_offline_setup
    Print.info "Validating offline RAG + CAG setup..."

    validation_issues = []

    # Check required directories
    required_directories = [
      @knowledge_base_path,
      @embedding_cache_path,
      @graph_cache_path
    ]

    required_directories.each do |dir|
      unless File.exist?(dir)
        validation_issues << "Missing required directory: #{dir}"
      end
    end

    # Check knowledge base files
    if @knowledge_loaded && File.exist?(@knowledge_base_path)
      builtin_path = File.join(@knowledge_base_path, 'builtin')
      unless File.exist?(builtin_path) && Dir.empty?(builtin_path)
        validation_issues << "Built-in knowledge base not found or empty"
      end
    end

    # Check configuration
    unless @config[:rag][:offline_mode] && @config[:cag][:offline_mode]
      validation_issues << "RAG or CAG offline mode not enabled in configuration"
    end

    if validation_issues.empty?
      Print.info "✓ Offline setup validation passed"
      true
    else
      Print.err "✗ Offline setup validation failed:"
      validation_issues.each { |issue| Print.err "  - #{issue}" }
      false
    end
  end

  def create_offline_package(output_path = nil)
    output_path ||= File.join(Dir.pwd, 'hackbot_offline_package.tar.gz')

    Print.info "Creating offline package at: #{output_path}"

    # This would create a compressed package containing all necessary files
    # For implementation, this would use system tar or rubygems compression

    begin
      require 'rubygems/package'
      require 'zlib'

      File.open(output_path, 'wb') do |file|
        Zlib::GzipWriter.wrap(file) do |gz|
          Gem::Package::TarWriter.new(gz) do |tar|
            # Add configuration files
            add_file_to_tar(tar, @config_path, 'config/offline_config.json')

            # Add knowledge bases
            add_directory_to_tar(tar, @knowledge_base_path, 'knowledge_bases')

            # Add cache files
            add_directory_to_tar(tar, @embedding_cache_path, 'cache/embeddings')
            add_directory_to_tar(tar, @graph_cache_path, 'cache/graph')

            # Add necessary scripts and libraries
            add_file_to_tar(tar, 'rag_cag_offline_config.rb', 'rag_cag_offline_config.rb')
          end
        end
      end

      Print.info "✓ Offline package created successfully: #{output_path}"
      true
    rescue => e
      Print.err "Failed to create offline package: #{e.message}"
      false
    end
  end

  private

  def deep_merge(base_hash, override_hash)
    merger = proc do |_, v1, v2|
      if v1.is_a?(Hash) && v2.is_a?(Hash)
        v1.merge(v2, &merger)
      else
        v2
      end
    end
    base_hash.merge(override_hash, &merger)
  end

  def collect_directory_stats(dir_path)
    return {} unless File.exist?(dir_path)

    files = Dir.glob(File.join(dir_path, '**', '*')).select { |f| File.file?(f) }
    directories = Dir.glob(File.join(dir_path, '**', '*')).select { |f| File.directory?(f) }

    {
      path: dir_path,
      exists: true,
      file_count: files.length,
      directory_count: directories.length,
      total_size_bytes: files.sum { |f| File.size(f) },
      last_modified: File.mtime(dir_path).iso8601
    }
  rescue => e
    { path: dir_path, exists: false, error: e.message }
  end

  def add_file_to_tar(tar, source_path, archive_path)
    return unless File.exist?(source_path)

    tar.add_file(archive_path, File.mtime(source_path)) do |tar_file|
      File.open(source_path, 'rb') { |f| tar_file.write(f.read) }
    end
  end

  def add_directory_to_tar(tar, source_dir, archive_base)
    return unless File.exist?(source_dir)

    Dir.glob(File.join(source_dir, '**', '*')).each do |file_path|
      relative_path = file_path.sub(source_dir, '').gsub(/^\//, '')
      archive_path = File.join(archive_base, relative_path)

      if File.directory?(file_path)
        tar.mkdir(archive_path, File.mtime(file_path)) unless archive_path == archive_base
      else
        add_file_to_tar(tar, file_path, archive_path)
      end
    end
  end
end

# Utility functions for offline mode
def setup_offline_rag_cag(config_path = nil)
  manager = OfflineConfigurationManager.new(config_path)
  manager.load_configuration
  manager.auto_detect_and_configure

  if manager.offline_mode?
    manager.load_offline_knowledge_bases
    manager.preload_embeddings
    manager.validate_offline_setup
  end

  {
    rag_config: manager.get_rag_config,
    cag_config: manager.get_cag_config,
    unified_config: manager.get_unified_config,
    offline_mode: manager.offline_mode?,
    manager: manager
  }
end

# Command line usage
if __FILE__ == $0
  puts "Hackerbot RAG + CAG Offline Configuration Manager"
  puts "=" * 50

  case ARGV[0]
  when 'enable'
    manager = OfflineConfigurationManager.new
    manager.load_configuration
    manager.enable_offline_mode
    puts "Offline mode enabled"

  when 'disable'
    manager = OfflineConfigurationManager.new
    manager.load_configuration
    manager.disable_offline_mode
    puts "Offline mode disabled"

  when 'status'
    manager = OfflineConfigurationManager.new
    manager.load_configuration
    manager.auto_detect_and_configure

    puts "Status: #{manager.offline_mode? ? 'OFFLINE' : 'ONLINE'}"
    if manager.offline_mode?
      stats = manager.get_offline_statistics
      puts "Knowledge bases loaded: #{stats[:knowledge_bases_loaded]}"
      puts "Knowledge base stats: #{stats[:knowledge_base_stats].inspect}"
    end

  when 'package'
    output_path = ARGV[1] || './hackbot_offline_package.tar.gz'
    manager = OfflineConfigurationManager.new
    manager.load_configuration

    if manager.create_offline_package(output_path)
      puts "Package created: #{output_path}"
    else
      puts "Package creation failed"
      exit 1
    end

  when 'validate'
    manager = OfflineConfigurationManager.new
    manager.load_configuration
    manager.enable_offline_mode

    if manager.validate_offline_setup
      puts "Validation passed"
      exit 0
    else
      puts "Validation failed"
      exit 1
    end

  else
    puts "Usage: #{$0} [enable|disable|status|package|validate]"
    puts
    puts "Commands:"
    puts "  enable    - Enable offline mode"
    puts "  disable   - Disable offline mode"
    puts "  status    - Show current status"
    puts "  package   - Create offline package"
    puts "  validate  - Validate offline setup"
  end
end
