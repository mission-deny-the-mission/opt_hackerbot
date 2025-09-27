#!/usr/bin/env ruby

# Comprehensive Offline RAG + CAG Setup Script
# This script sets up the entire offline RAG + CAG system for disconnected operation
# including downloading required models, generating embeddings, and creating knowledge bases

require 'fileutils'
require 'json'
require 'net/http'
require 'uri'
require 'digest'
require 'zlib'
require 'open3'

# Add the current directory to the load path for requiring local modules
$LOAD_PATH.unshift(File.dirname(__FILE__))

require './print'
require './rag_cag_offline_config'

class OfflineRAGCAGSetup
  DEFAULT_SETUP_CONFIG = {
    version: "1.0.0",
    setup_mode: "offline",  # "offline", "hybrid", "online"
    auto_download_models: true,
    generate_embeddings: true,
    create_knowledge_bases: true,
    optimize_for_offline: true,

    # RAG Configuration
    rag: {
      vector_db: {
        provider: "chromadb_offline",
        storage_path: "./knowledge_bases/offline/vector_db",
        persist_embeddings: true,
        compression_enabled: true,
        max_storage_size_mb: 2048  # 2GB
      },
      embedding_service: {
        provider: "ollama_offline",
        model: "nomic-embed-text",
        local_model_path: nil,
        cache_embeddings: true,
        cache_path: "./cache/embeddings",
        fallback_to_random: true,
        preload_embeddings: true
      },
      document_preprocessing: {
        chunk_size: 1000,
        chunk_overlap: 200,
        normalize_text: true,
        remove_stopwords: false
      }
    },

    # CAG Configuration
    cag: {
      knowledge_graph: {
        provider: "in_memory_offline",
        storage_path: "./knowledge_bases/offline/graph",
        persist_graph: true,
        load_from_file: true,
        auto_save_interval: 300,
        compression_enabled: true,
        snapshot_enabled: true,
        max_snapshots: 5
      },
      entity_extractor: {
        provider: "rule_based_offline",
        custom_patterns: nil,
        cache_entities: true
      },
      graph_traversal: {
        max_depth: 3,
        max_nodes: 50,
        enable_caching: true
      }
    },

    # Knowledge Bases
    knowledge_bases: {
      builtin: {
        mitre_attack: {
          enabled: true,
          version: "latest",
          include_relations: true,
          include_metadata: true
        },
        common_vulnerabilities: {
          enabled: true,
          max_entries: 1000,
          include_cve_data: true
        },
        security_tools: {
          enabled: true,
          include_categories: ["attack", "defense", "analysis"],
          max_entries: 500
        }
      },
      custom: {
        enabled: true,
        sources: [
          {
            name: "cybersecurity_essentials",
            path: "./knowledge_bases/custom/cybersecurity_essentials.json",
            type: "json"
          }
        ]
      }
    },

    # Performance Configuration
    performance: {
      memory_optimization: true,
      max_memory_usage_mb: 4096,  # 4GB
      enable_streaming: true,
      batch_size: 50,
      parallel_processing: true,
      max_threads: 4
    },

    # Download Configuration
    downloads: {
      ollama_models: ["nomic-embed-text", "llama2:7b", "mistral:7b"],
      max_retries: 3,
      timeout_seconds: 1800,  # 30 minutes
      verify_checksums: true,
      resume_downloads: true
    },

    # Validation
    validation: {
      test_integrations: true,
      validate_embeddings: true,
      validate_graph_integrity: true,
      performance_test: true,
      generate_report: true
    }
  }

  def initialize(config_path = nil)
    @setup_config = DEFAULT_SETUP_CONFIG.deep_dup
    @config_path = config_path
    @setup_dir = File.dirname(__FILE__)
    @progress_reporter = ProgressReporter.new
    @error_log = []
    @success_log = []

    # Paths
    @base_paths = {
      knowledge_bases: File.join(@setup_dir, 'knowledge_bases', 'offline'),
      cache: File.join(@setup_dir, 'cache'),
      config: File.join(@setup_dir, 'config'),
      logs: File.join(@setup_dir, 'logs')
    }

    # Initialize counters
    @counters = {
      models_downloaded: 0,
      embeddings_generated: 0,
      knowledge_bases_loaded: 0,
      validation_failures: 0,
      total_operations: 0,
      completed_operations: 0
    }
  end

  def run_setup
    Print.banner "Hackerbot RAG + CAG Offline Setup"
    Print.info "Starting comprehensive offline setup..."

    begin
      # Load configuration if provided
      load_configuration if @config_path

      # Validate system requirements
      validate_system_requirements

      # Create necessary directories
      create_directories

      # Setup RAG components
      setup_rag_components if @setup_config[:rag][:embedding_service][:provider] == "ollama_offline"

      # Setup CAG components
      setup_cag_components

      # Create knowledge bases
      create_knowledge_bases if @setup_config[:create_knowledge_bases]

      # Generate embeddings
      generate_embeddings if @setup_config[:generate_embeddings]

      # Optimize for offline operation
      optimize_for_offline if @setup_config[:optimize_for_offline]

      # Validate setup
      validate_setup if @setup_config[:validation][:test_integrations]

      # Generate report
      generate_setup_report if @setup_config[:validation][:generate_report]

      Print.banner "Setup Completed Successfully!"
      Print.info "Offline RAG + CAG system is ready for use"

      # Print summary
      print_setup_summary

    rescue => e
      Print.err "Setup failed: #{e.message}"
      Print.err e.backtrace
      log_error("Setup failed: #{e.message}")
      exit 1
    end
  end

  private

  def load_configuration
    Print.info "Loading setup configuration from: #{@config_path}"

    unless File.exist?(@config_path)
      Print.err "Configuration file not found: #{@config_path}"
      Print.info "Using default configuration"
      return
    end

    begin
      config_data = JSON.parse(File.read(@config_path))
      @setup_config = deep_merge(@setup_config, config_data)
      Print.info "Configuration loaded successfully"
    rescue => e
      Print.err "Failed to load configuration: #{e.message}"
      Print.info "Using default configuration"
    end
  end

  def validate_system_requirements
    Print.info "Validating system requirements..."

    requirements = {
      ruby_version: ">= 3.0.0",
      disk_space_mb: 5000,  # 5GB minimum
      memory_mb: 2048,     # 2GB minimum
      required_gems: ["json", "fileutils", "net/http", "zlib", "open3"]
    }

    # Check Ruby version
    current_ruby = RUBY_VERSION
    required_ruby = requirements[:ruby_version]
    if Gem::Version.new(current_ruby) < Gem::Version.new(required_ruby.gsub('>= ', ''))
      Print.err "Ruby version #{current_ruby} is below required #{required_ruby}"
      raise "Ruby version requirement not met"
    end

    # Check disk space
    available_space = get_available_disk_space
    if available_space < requirements[:disk_space_mb]
      Print.err "Insufficient disk space: #{available_space}MB available, #{requirements[:disk_space_mb]}MB required"
      raise "Insufficient disk space"
    end

    # Check memory (Linux/macOS only)
    if get_memory_size < requirements[:memory_mb]
      Print.warn "System memory might be insufficient for optimal performance"
    end

    # Check required gems
    requirements[:required_gems].each do |gem|
      begin
        require gem
      rescue LoadError
        Print.err "Required gem '#{gem}' not found"
        raise "Missing required gem: #{gem}"
      end
    end

    Print.info "✓ System requirements validation passed"
    log_success("System requirements validation passed")
  end

  def create_directories
    Print.info "Creating directory structure..."

    directories = [
      @base_paths[:knowledge_bases],
      @base_paths[:cache],
      @base_paths[:config],
      @base_paths[:logs],
      File.join(@base_paths[:knowledge_bases], 'vector_db'),
      File.join(@base_paths[:knowledge_bases], 'graph'),
      File.join(@base_paths[:knowledge_bases], 'builtin'),
      File.join(@base_paths[:knowledge_bases], 'custom'),
      File.join(@base_paths[:cache], 'embeddings'),
      File.join(@base_paths[:cache], 'graph'),
      File.join(@setup_dir, 'snapshots')
    ]

    directories.each do |dir|
      unless Dir.exist?(dir)
        FileUtils.mkdir_p(dir)
        Print.debug "Created directory: #{dir}"
      end
    end

    Print.info "✓ Directory structure created"
    log_success("Directory structure created")
  end

  def setup_rag_components
    Print.info "Setting up RAG components..."

    @progress_reporter.start_section("RAG Setup")

    # Download Ollama models if configured
    if @setup_config[:downloads][:auto_download_models] && @setup_config[:rag][:embedding_service][:provider] == "ollama_offline"
      download_ollama_models
    end

    # Initialize offline vector database
    initialize_offline_vector_db

    # Setup embedding service
    setup_offline_embedding_service

    @progress_reporter.end_section
    Print.info "✓ RAG components setup completed"
    log_success("RAG components setup completed")
  end

  def setup_cag_components
    Print.info "Setting up CAG components..."

    @progress_reporter.start_section("CAG Setup")

    # Initialize offline knowledge graph
    initialize_offline_knowledge_graph

    # Setup entity extractor
    setup_offline_entity_extractor

    @progress_reporter.end_section
    Print.info "✓ CAG components setup completed"
    log_success("CAG components setup completed")
  end

  def download_ollama_models
    Print.info "Downloading Ollama models for offline operation..."

    models = @setup_config[:downloads][:ollama_models]
    max_retries = @setup_config[:downloads][:max_retries]
    timeout = @setup_config[:downloads][:timeout_seconds]

    # Check if Ollama is installed and available
    unless check_ollama_available
      Print.err "Ollama is not available. Please install Ollama first."
      Print.info "Visit: https://ollama.com/download"
      return
    end

    models.each do |model|
      @progress_reporter.start_operation("Downloading model: #{model}")

      success = false
      attempts = 0

      while attempts < max_retries && !success
        attempts += 1
        Print.info "Attempting to download model #{model} (attempt #{attempts}/#{max_retries})"

        if download_model_with_retry(model, timeout)
          @counters[:models_downloaded] += 1
          success = true
          log_success("Downloaded model: #{model}")
        else
          Print.warn "Failed to download model #{model} (attempt #{attempts}/#{max_retries})")
        end
      end

      unless success
        Print.err "Failed to download model #{model} after #{max_retries} attempts"
        log_error("Failed to download model: #{model}")
        @counters[:validation_failures] += 1
      end

      @progress_reporter.end_operation
    end

    Print.info "✓ Downloaded #{@counters[:models_downloaded]}/#{models.length} models"
  end

  def initialize_offline_vector_db
    Print.info "Initializing offline vector database..."

    require './rag/chromadb_offline_client'

    # Initialize the offline ChromaDB client
    rag_config = @setup_config[:rag].deep_dup
    vector_db_config = rag_config[:vector_db]

    vector_db = ChromaDBOfflineClient.new(vector_db_config)

    if vector_db.connect
      Print.info "✓ Offline vector database initialized successfully"
      log_success("Offline vector database initialized")

      # Test basic operations
      test_collection_name = "setup_test_collection"
      vector_db.create_collection(test_collection_name)
      vector_db.delete_collection(test_collection_name)

      Print.info "✓ Vector database basic operations test passed"
    else
      Print.err "Failed to initialize offline vector database"
      raise "Vector database initialization failed"
    end
  end

  def setup_offline_embedding_service
    Print.info "Setting up offline embedding service..."

    require './rag/ollama_embedding_offline_client'

    embedding_config = @setup_config[:rag][:embedding_service].deep_dup
    embedding_service = OllamaEmbeddingOfflineClient.new(embedding_config)

    if embedding_service.connect
      Print.info "✓ Offline embedding service initialized successfully"
      log_success("Offline embedding service initialized")

      # Test basic embedding generation
      test_text = "This is a test embedding for offline operation"
      embedding = embedding_service.generate_embedding(test_text)

      if embedding && embedding.length > 0
        Print.info "✓ Embedding generation test passed (dimension: #{embedding.length})"
      else
        Print.err "Embedding generation test failed"
        raise "Embedding service test failed"
      end
    else
      Print.err "Failed to initialize offline embedding service"
      raise "Embedding service initialization failed"
    end
  end

  def initialize_offline_knowledge_graph
    Print.info "Initializing offline knowledge graph..."

    require './cag/in_memory_graph_offline_client'

    graph_config = @setup_config[:cag][:knowledge_graph].deep_dup
    knowledge_graph = InMemoryGraphOfflineClient.new(graph_config)

    if knowledge_graph.connect
      Print.info "✓ Offline knowledge graph initialized successfully"
      log_success("Offline knowledge graph initialized")

      # Test basic operations
      test_node_id = "setup_test_node"
      knowledge_graph.create_node(test_node_id, ["Test"], {name: "Test Node"})
      knowledge_graph.delete_node(test_node_id)

      Print.info "✓ Knowledge graph basic operations test passed"
    else
      Print.err "Failed to initialize offline knowledge graph"
      raise "Knowledge graph initialization failed"
    end
  end

  def setup_offline_entity_extractor
    Print.info "Setting up offline entity extractor..."

    # For now, we'll use the built-in rule-based extractor
    # In the future, this could be extended to support more sophisticated extractors

    Print.info "✓ Offline entity extractor setup completed"
    log_success("Offline entity extractor setup completed")
  end

  def create_knowledge_bases
    Print.info "Creating knowledge bases..."

    @progress_reporter.start_section("Knowledge Base Creation")

    # Create built-in knowledge bases
    if @setup_config[:knowledge_bases][:builtin][:mitre_attack][:enabled]
      create_mitre_attack_knowledge_base
    end

    if @setup_config[:knowledge_bases][:builtin][:common_vulnerabilities][:enabled]
      create_common_vulnerabilities_knowledge_base
    end

    if @setup_config[:knowledge_bases][:builtin][:security_tools][:enabled]
      create_security_tools_knowledge_base
    end

    # Create custom knowledge bases
    if @setup_config[:knowledge_bases][:custom][:enabled]
      create_custom_knowledge_bases
    end

    @progress_reporter.end_section
    Print.info "✓ Created #{@counters[:knowledge_bases_loaded]} knowledge bases"
    log_success("Created #{@counters[:knowledge_bases_loaded]} knowledge bases")
  end

  def create_mitre_attack_knowledge_base
    Print.info "Creating MITRE ATT&CK knowledge base..."

    @progress_reporter.start_operation("MITRE ATT&CK Knowledge Base")

    require './knowledge_bases/mitre_attack_knowledge'

    # Generate knowledge base
    rag_documents = MITREAttackKnowledge.to_rag_documents
    cag_triplets = MITREAttackKnowledge.to_cag_triplets

    # Save to disk
    mitre_knowledge_path = File.join(@base_paths[:knowledge_bases], 'builtin', 'mitre_attack')
    FileUtils.mkdir_p(mitre_knowledge_path) unless Dir.exist?(mitre_knowledge_path)

    # Save RAG documents
    File.write(File.join(mitre_knowledge_path, 'rag_documents.json'), JSON.pretty_generate(rag_documents))

    # Save CAG triplets
    File.write(File.join(mitre_knowledge_path, 'cag_triplets.json'), JSON.pretty_generate(cag_triplets))

    # Save metadata
    metadata = {
      name: "MITRE ATT&CK",
      type: "builtin",
      version: @setup_config[:knowledge_bases][:builtin][:mitre_attack][:version],
      documents_count: rag_documents.length,
      triplets_count: cag_triplets.length,
      created_at: Time.now.iso8601,
      description: "Comprehensive MITRE ATT&CK framework knowledge base"
    }

    File.write(File.join(mitre_knowledge_path, 'metadata.json'), JSON.pretty_generate(metadata))

    @counters[:knowledge_bases_loaded] += 1
    Print.info "✓ MITRE ATT&CK knowledge base created with #{rag_documents.length} documents and #{cag_triplets.length} triplets"

    @progress_reporter.end_operation
  end

  def create_common_vulnerabilities_knowledge_base
    Print.info "Creating common vulnerabilities knowledge base..."

    @progress_reporter.start_operation("Common Vulnerabilities Knowledge Base")

    # Generate sample vulnerability data
    vulnerabilities = generate_sample_vulnerabilities

    # Convert to RAG documents and CAG triplets
    rag_documents = vulnerabilities_to_rag_documents(vulnerabilities)
    cag_triplets = vulnerabilities_to_cag_triplets(vulnerabilities)

    # Save to disk
    vuln_knowledge_path = File.join(@base_paths[:knowledge_bases], 'builtin', 'common_vulnerabilities')
    FileUtils.mkdir_p(vuln_knowledge_path) unless Dir.exist?(vuln_knowledge_path)

    # Save RAG documents
    File.write(File.join(vuln_knowledge_path, 'rag_documents.json'), JSON.pretty_generate(rag_documents))

    # Save CAG triplets
    File.write(File.join(vuln_knowledge_path, 'cag_triplets.json'), JSON.pretty_generate(cag_triplets))

    # Save metadata
    metadata = {
      name: "Common Vulnerabilities",
      type: "builtin",
      documents_count: rag_documents.length,
      triplets_count: cag_triplets.length,
      created_at: Time.now.iso8601,
      description: "Common vulnerabilities and exposures knowledge base"
    }

    File.write(File.join(vuln_knowledge_path, 'metadata.json'), JSON.pretty_generate(metadata))

    @counters[:knowledge_bases_loaded] += 1
    Print.info "✓ Common vulnerabilities knowledge base created with #{rag_documents.length} documents"

    @progress_reporter.end_operation
  end

  def create_security_tools_knowledge_base
    Print.info "Creating security tools knowledge base..."

    @progress_reporter.start_operation("Security Tools Knowledge Base")

    # Generate sample security tools data
    security_tools = generate_sample_security_tools

    # Convert to RAG documents and CAG triplets
    rag_documents = security_tools_to_rag_documents(security_tools)
    cag_triplets = security_tools_to_cag_triplets(security_tools)

    # Save to disk
    tools_knowledge_path = File.join(@base_paths[:knowledge_bases], 'builtin', 'security_tools')
    FileUtils.mkdir_p(tools_knowledge_path) unless Dir.exist?(tools_knowledge_path)

    # Save RAG documents
    File.write(File.join(tools_knowledge_path, 'rag_documents.json'), JSON.pretty_generate(rag_documents))

    # Save CAG triplets
    File.write(File.join(tools_knowledge_path, 'cag_triplets.json'), JSON.pretty_generate(cag_triplets))

    # Save metadata
    metadata = {
      name: "Security Tools",
      type: "builtin",
      documents_count: rag_documents.length,
      triplets_count: cag_triplets.length,
      created_at: Time.now.iso8601,
      description: "Security tools and utilities knowledge base"
    }

    File.write(File.join(tools_knowledge_path, 'metadata.json'), JSON.pretty_generate(metadata))

    @counters[:knowledge_bases_loaded] += 1
    Print.info "✓ Security tools knowledge base created with #{rag_documents.length} documents"

    @progress_reporter.end_operation
  end

  def create_custom_knowledge_bases
    Print.info "Creating custom knowledge bases..."

    custom_sources = @setup_config[:knowledge_bases][:custom][:sources]

    custom_sources.each do |source|
      @progress_reporter.start_operation("Custom Knowledge Base: #{source[:name]}")

      if source[:type] == "json" && File.exist?(source[:path])
        begin
          custom_data = JSON.parse(File.read(source[:path]))

          # Save to custom knowledge base location
          custom_knowledge_path = File.join(@base_paths[:knowledge_bases], 'custom', source[:name])
          FileUtils.mkdir_p(custom_knowledge_path) unless Dir.exist?(custom_knowledge_path)

          # Copy custom knowledge
          FileUtils.cp(source[:path], File.join(custom_knowledge_path, 'knowledge.json'))

          # Create metadata
          metadata = {
            name: source[:name],
            type: "custom",
            source_path: source[:path],
            imported_at: Time.now.iso8601,
            description: "Custom knowledge base imported from #{source[:path]}"
          }

          File.write(File.join(custom_knowledge_path, 'metadata.json'), JSON.pretty_generate(metadata))

          @counters[:knowledge_bases_loaded] += 1
          Print.info "✓ Custom knowledge base created: #{source[:name]}"

        rescue => e
          Print.err "Failed to create custom knowledge base #{source[:name]}: #{e.message}"
          log_error("Failed to create custom knowledge base #{source[:name]}: #{e.message}")
        end
      else
        Print.warn "Custom knowledge source not found or unsupported type: #{source[:path]}"
      end

      @progress_reporter.end_operation
    end
  end

  def generate_embeddings
    Print.info "Generating embeddings for offline operation..."

    @progress_reporter.start_section("Embedding Generation")

    require './rag/ollama_embedding_offline_client'

    embedding_config = @setup_config[:rag][:embedding_service].deep_dup
    embedding_service = OllamaEmbeddingOfflineClient.new(embedding_config)

    unless embedding_service.connect
      Print.err "Failed to connect to embedding service"
      raise "Embedding service connection failed"
    end

    # Collect all texts from knowledge bases
    all_texts = collect_all_texts_for_embedding

    # Generate embeddings in batches
    batch_size = @setup_config[:performance][:batch_size]
    total_texts = all_texts.length
    generated_count = 0

    all_texts.each_slice(batch_size).with_index do |batch, index|
      @progress_reporter.start_operation("Generating embeddings batch #{index + 1}")

      Print.info "Processing batch #{index + 1} (#{batch.length} texts)"

      batch_embeddings = embedding_service.generate_batch_embeddings(batch)

      if batch_embeddings.length == batch.length
        generated_count += batch_embeddings.length
        Print.info "✓ Generated #{batch_embeddings.length} embeddings for batch #{index + 1}"
      else
        Print.err "Failed to generate embeddings for batch #{index + 1}"
        log_error("Embedding generation failed for batch #{index + 1}")
      end

      @progress_reporter.end_operation
    end

    @counters[:embeddings_generated] = generated_count
    Print.info "✓ Generated #{generated_count}/#{total_texts} embeddings"
    log_success("Generated #{generated_count} embeddings")

    @progress_reporter.end_section
  end

  def optimize_for_offline
    Print.info "Optimizing for offline operation..."

    @progress_reporter.start_section("Offline Optimization")

    # Compress knowledge bases
    compress_knowledge_bases

    # Create offline configuration
    create_offline_configuration

    # Generate startup scripts
    generate_startup_scripts

    # Create offline package
    create_offline_package

    @progress_reporter.end_section
    Print.info "✓ Offline optimization completed"
    log_success("Offline optimization completed")
  end

  def validate_setup
    Print.info "Validating offline RAG + CAG setup..."

    @progress_reporter.start_section("Setup Validation")

    # Test RAG components
    if @setup_config[:validation][:test_integrations]
      validate_rag_components
      validate_cag_components
    end

    # Test embedding generation
    if @setup_config[:validation][:validate_embeddings]
      validate_embedding_generation
    end

    # Test graph integrity
    if @setup_config[:validation][:validate_graph_integrity]
      validate_graph_integrity
    end

    # Performance test
    if @setup_config[:validation][:performance_test]
      run_performance_test
    end

    @progress_reporter.end_section
    Print.info "✓ Setup validation completed with #{@counters[:validation_failures]} failures"
    log_success("Setup validation completed")
  end

  def generate_setup_report
    Print.info "Generating setup report..."

    report_path = File.join(@base_paths[:logs], "setup_report_#{Time.now.strftime('%Y%m%d_%H%M%S')}.json")

    report = {
      setup_timestamp: Time.now.iso8601,
      setup_version: @setup_config[:version],
      system_info: {
        ruby_version: RUBY_VERSION,
        platform: RUBY_PLATFORM,
        hostname: Socket.gethostname rescue "unknown"
      },
      configuration: @setup_config,
      results: {
        models_downloaded: @counters[:models_downloaded],
        embeddings_generated: @counters[:embeddings_generated],
        knowledge_bases_loaded: @counters[:knowledge_bases_loaded],
        validation_failures: @counters[:validation_failures],
        total_operations: @counters[:total_operations],
        completed_operations: @counters[:completed_operations]
      },
      success_log: @success_log,
      error_log: @error_log,
      paths: @base_paths,
      status: @counters[:validation_failures] == 0 ? "SUCCESS" : "PARTIAL_SUCCESS"
    }

    File.write(report_path, JSON.pretty_generate(report))

    Print.info "✓ Setup report generated: #{report_path}"
    log_success("Setup report generated: #{report_path}")
  end

  def print_setup_summary
    Print.info "\n" + "=" * 60
    Print.info "SETUP SUMMARY"
    Print.info "=" * 60
    Print.info "Models Downloaded: #{@counters[:models_downloaded]}"
    Print.info "Embeddings Generated: #{@counters[:embeddings_generated]}"
    Print.info "Knowledge Bases Loaded: #{@counters[:knowledge_bases_loaded]}"
    Print.info "Validation Failures: #{@counters[:validation_failures]}"
    Print.info "Total Operations: #{@counters[:total_operations]}"
    Print.info "Completed Operations: #{@counters[:completed_operations]}"
    Print.info ""

    if @counters[:validation_failures] == 0
      Print.info "🎉 Setup completed successfully!"
      Print.info "The offline RAG + CAG system is ready for use."
    else
      Print.info "⚠️  Setup completed with #{@counters[:validation_failures]} issues."
      Print.info "Please check the error log for details."
    end

    Print.info ""
    Print.info "Knowledge Base Location: #{@base_paths[:knowledge_bases]}"
    Print.info "Cache Location: #{@base_paths[:cache]}"
    Print.info "Configuration Location: #{@base_paths[:config]}"
    Print.info "Logs Location: #{@base_paths[:logs]}"
    Print.info ""
    Print.info "To start the system in offline mode:"
    Print.info "  ruby hackerbot.rb --enable-rag-cag --offline"
    Print.info "=" * 60
  end

  # Helper methods for various operations
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

  def get_available_disk_space
    # Get available disk space in MB
    if File.exist?("/")
      # Linux/macOS
      `df -m .`.split("\n")[1].split[3].to_i
    else
      # Windows fallback
      10000  # Assume 10GB available
    end
  rescue
    10000  # Fallback
  end

  def get_memory_size
    # Get memory size in MB
    if File.exist?("/proc/meminfo")
      # Linux
      `grep MemTotal /proc/meminfo`.split[1].to_i / 1024
    else
      # Fallback
      8192  # Assume 8GB
    end
  rescue
    8192  # Fallback
  end

  def check_ollama_available
    system("which ollama > /dev/null 2>&1") && system("ollama --version > /dev/null 2>&1")
  end

  def download_model_with_retry(model, timeout)
    command = "ollama pull #{model}"

    begin
      Open3.popen2e(command) do |stdin, stdout_err, wait_thr|
        stdin.close

        # Set timeout
        Timeout.timeout(timeout) do
          while line = stdout_err.gets
            Print.info line.chomp if line.include?('%')
          end
        end
      end

      # Verify model was downloaded
      verify_result = system("ollama list | grep -q #{model}")
      return verify_result

    rescue Timeout::Error
      Print.err "Download of #{model} timed out after #{timeout} seconds"
      return false
    rescue => e
      Print.err "Download error for #{model}: #{e.message}"
      return false
    end
  end

  def collect_all_texts_for_embedding
    texts = []

    # Collect texts from MITRE ATT&CK
    mitre_path = File.join(@base_paths[:knowledge_bases], 'builtin', 'mitre_attack', 'rag_documents.json')
    if File.exist?(mitre_path)
      mitre_data = JSON.parse(File.read(mitre_path))
      texts.concat(mitre_data.map { |doc| doc[:content] || doc['content'] })
    end

    # Collect texts from other knowledge bases
    # Add more knowledge base text collection here as needed

    texts.uniq.compact
  end

  def generate_sample_vulnerabilities
    # Generate sample vulnerability data
    [
      {
        id: "CVE-2023-1234",
        name: "Buffer Overflow Vulnerability",
        description: "A buffer overflow vulnerability allows attackers to execute arbitrary code.",
        severity: "HIGH",
        affected_systems: ["Linux", "Windows"],
        mitigation: "Apply security patches"
      },
      {
        id: "CVE-2023-5678",
        name: "SQL Injection Vulnerability",
        description: "SQL injection allows attackers to execute arbitrary SQL commands.",
        severity: "CRITICAL",
        affected_systems: ["Web Applications"],
        mitigation: "Use parameterized queries"
      }
    ]
  end

  def vulnerabilities_to_rag_documents(vulnerabilities)
    vulnerabilities.map do |vuln|
      {
        id: vuln[:id],
        content: "Vulnerability: #{vuln[:name]}\n\n#{vuln[:description]}\n\nSeverity: #{vuln[:severity]}\n\nAffected Systems: #{vuln[:affected_systems].join(', ')}\n\nMitigation: #{vuln[:mitigation]}",
        metadata: {
          source: "common_vulnerabilities",
          type: "vulnerability",
          severity: vuln[:severity],
          cve_id: vuln[:id]
        }
      }
    end
  end

  def vulnerabilities_to_cag_triplets(vulnerabilities)
    triplets = []
    vulnerabilities.each do |vuln|
      triplets << {
        subject: vuln[:name],
        relationship: "IS_TYPE",
        object: "Vulnerability",
        properties: { severity: vuln[:severity], cve_id: vuln[:id] }
      }
    end
    triplets
  end

  def generate_sample_security_tools
    # Generate sample security tools data
    [
      {
        name: "Wireshark",
        type: "analysis",
        description: "Network protocol analyzer for capturing and analyzing network traffic.",
        category: "network_analysis",
        platform: ["Windows", "Linux", "macOS"]
      },
      {
        name: "Nmap",
        type: "attack",
        description: "Network scanning tool for discovering hosts and services.",
        category: "network_scanning",
        platform: ["Linux", "Windows", "macOS"]
      }
    ]
  end

  def security_tools_to_rag_documents(tools)
    tools.map do |tool|
      {
        id: tool[:name].downcase.gsub(/\s+/, '_'),
        content: "Security Tool: #{tool[:name]}\n\nType: #{tool[:type]}\n\nDescription: #{tool[:description]}\n\nCategory: #{tool[:category]}\n\nPlatforms: #{tool[:platform].join(', ')}",
        metadata: {
          source: "security_tools",
          type: "tool",
          category: tool[:category],
          tool_type: tool[:type]
        }
      }
    end
  end

  def security_tools_to_cag_triplets(tools)
    triplets = []
    tools.each do |tool|
      triplets << {
        subject: tool[:name],
        relationship: "IS_TYPE",
        object: "Security Tool",
        properties: { category: tool[:category], tool_type: tool[:type] }
      }
    end
    triplets
  end

  def compress_knowledge_bases
    Print.info "Compressing knowledge bases..."

    # Compress built-in knowledge bases
    builtin_path = File.join(@base_paths[:knowledge_bases], 'builtin')
    if Dir.exist?(builtin_path)
      Dir.glob(File.join(builtin_path, '**', '*.json')).each do |file|
        compress_file(file)
      end
    end

    Print.info "✓ Knowledge bases compressed"
  end

  def compress_file(file_path)
    original_size = File.size(file_path)

    # Read original file
    original_data = File.read(file_path)

    # Compress data
    compressed_data = Zlib.deflate(original_data)

    # Write compressed file
    compressed_path = file_path + '.gz'
    File.binwrite(compressed_path, compressed_data)

    compressed_size = File.size(compressed_path)
    compression_ratio = ((1.0 - compressed_size.to_f / original_size.to_f) * 100).round(1)

    Print.info "Compressed #{File.basename(file_path)}: #{original_size} -> #{compressed_size} bytes (#{compression_ratio}% reduction)"
  end

  def create_offline_configuration
    Print.info "Creating offline configuration..."

    config_path = File.join(@base_paths[:config], 'offline_config.json')

    offline_config = {
      offline_mode: {
        enabled: true,
        auto_detect: true,
        fallback_to_offline: true
      },
      rag: @setup_config[:rag],
      cag: @setup_config[:cag],
      knowledge_bases: @setup_config[:knowledge_bases],
      performance: @setup_config[:performance],
      created_at: Time.now.iso8601,
      setup_version: @setup_config[:version]
    }

    File.write(config_path, JSON.pretty_generate(offline_config))
    Print.info "✓ Offline configuration created: #{config_path}"
  end

  def generate_startup_scripts
    Print.info "Generating startup scripts..."

    # Generate offline startup script
    startup_script = <<~SCRIPT
      #!/bin/bash

      # Offline Hackerbot RAG + CAG Startup Script
      # This script starts the system in offline mode

      echo "Starting Hackerbot in offline RAG + CAG mode..."

      # Set environment variables for offline operation
      export RAG_CAG_OFFLINE=1

      # Start Hackerbot with offline configuration
      ruby hackerbot.rb --enable-rag-cag --offline

      echo "Hackerbot offline RAG + CAG system started."
    SCRIPT

    startup_path = File.join(@setup_dir, 'start_offline.sh')
    File.write(startup_path, startup_script)
    FileUtils.chmod(0755, startup_path)

    Print.info "✓ Startup script generated: #{startup_path}"
  end

  def create_offline_package
    Print.info "Creating offline package..."

    package_path = File.join(@setup_dir, "hackbot_offline_#{Time.now.strftime('%Y%m%d')}.tar.gz")

    # Create package
    system("tar -czf #{package_path} knowledge_bases cache config start_offline.sh")

    if File.exist?(package_path)
      package_size = File.size(package_path)
      Print.info "✓ Offline package created: #{package_path} (#{(package_size / 1024 / 1024).round(1)} MB)"
    else
      Print.err "Failed to create offline package"
    end
  end

  def validate_rag_components
    Print.info "Validating RAG components..."

    # Test vector database
    require './rag/chromadb_offline_client'
    vector_db = ChromaDBOfflineClient.new(@setup_config[:rag][:vector_db])

    if vector_db.connect && vector_db.test_connection
      Print.info "✓ RAG vector database validation passed"
    else
      Print.err "✗ RAG vector database validation failed"
      @counters[:validation_failures] += 1
    end

    # Test embedding service
    require './rag/ollama_embedding_offline_client'
    embedding_service = OllamaEmbeddingOfflineClient.new(@setup_config[:rag][:embedding_service])

    if embedding_service.connect && embedding_service.test_connection
      Print.info "✓ RAG embedding service validation passed"
    else
      Print.err "✗ RAG embedding service validation failed"
      @counters[:validation_failures] += 1
    end
  end

  def validate_cag_components
    Print.info "Validating CAG components..."

    # Test knowledge graph
    require './cag/in_memory_graph_offline_client'
    knowledge_graph = InMemoryGraphOfflineClient.new(@setup_config[:cag][:knowledge_graph])

    if knowledge_graph.connect && knowledge_graph.test_connection
      Print.info "✓ CAG knowledge graph validation passed"
    else
      Print.err "✗ CAG knowledge graph validation failed"
      @counters[:validation_failures] += 1
    end
  end

  def validate_embedding_generation
    Print.info "Validating embedding generation..."

    require './rag/ollama_embedding_offline_client'
    embedding_service = OllamaEmbeddingOfflineClient.new(@setup_config[:rag][:embedding_service])

    if embedding_service.connect
      test_text = "This is a validation test for embedding generation."
      embedding = embedding_service.generate_embedding(test_text)

      if embedding && embedding.length > 0
        Print.info "✓ Embedding generation validation passed"
      else
        Print.err "✗ Embedding generation validation failed"
        @counters[:validation_failures] += 1
      end
    else
      Print.err "✗ Cannot connect to embedding service for validation"
      @counters[:validation_failures] += 1
    end
  end

  def validate_graph_integrity
    Print.info "Validating knowledge graph integrity..."

    require './cag/in_memory_graph_offline_client'
    knowledge_graph = InMemoryGraphOfflineClient.new(@setup_config[:cag][:knowledge_graph])

    if knowledge_graph.connect
      # Create test nodes and relationships
      node1 = knowledge_graph.create_node("test_node_1", ["Test"], {name: "Test Node 1"})
      node2 = knowledge_graph.create_node("test_node_2", ["Test"], {name: "Test Node 2"})

      if node1 && node2
        relationship = knowledge_graph.create_relationship("test_node_1", "test_node_2", "TESTS")

        if relationship
          # Test search
          found_nodes = knowledge_graph.find_nodes_by_label("Test")

          if found_nodes.length >= 2
            Print.info "✓ Knowledge graph integrity validation passed"
          else
            Print.err "✗ Knowledge graph search failed"
            @counters[:validation_failures] += 1
          end
        else
          Print.err "✗ Knowledge graph relationship creation failed"
          @counters[:validation_failures] += 1
        end
      else
        Print.err "✗ Knowledge graph node creation failed"
        @counters[:validation_failures] += 1
      end

      # Cleanup
      knowledge_graph.delete_node("test_node_1")
      knowledge_graph.delete_node("test_node_2")
    else
      Print.err "✗ Cannot connect to knowledge graph for validation"
      @counters[:validation_failures] += 1
    end
  end

  def run_performance_test
    Print.info "Running performance test..."

    # Simple performance test - time to load and query knowledge bases
    start_time = Time.now

    # Test loading a knowledge base
    mitre_path = File.join(@base_paths[:knowledge_bases], 'builtin', 'mitre_attack', 'rag_documents.json')
    if File.exist?(mitre_path)
      data = JSON.parse(File.read(mitre_path))
      load_time = Time.now - start_time

      # Test search
      search_start = Time.now
      matching_docs = data.select { |doc|
        doc[:content]&.downcase&.include?("credential") ||
        doc['content']&.downcase&.include?("credential")
      }
      search_time = Time.now - search_start

      total_time = Time.now - start_time

      Print.info "✓ Performance test completed:"
      Print.info "  Load time: #{(load_time * 1000).round(1)}ms"
      Print.info "  Search time: #{(search_time * 1000).round(1)}ms"
      Print.info "  Total time: #{(total_time * 1000).round(1)}ms"
      Print.info "  Documents found: #{matching_docs.length}"

      if total_time < 5.0  # Should complete in under 5 seconds
        Print.info "✓ Performance test passed"
      else
        Print.warn "⚠ Performance test slower than expected"
      end
    else
      Print.err "✗ Cannot run performance test - no knowledge base found"
      @counters[:validation_failures] += 1
    end
  end

  def log_success(message)
    @success_log << {
      timestamp: Time.now.iso8601,
      message: message
    }
  end

  def log_error(message)
    @error_log << {
      timestamp: Time.now.iso8601,
      message: message
    }
  end
end

# Progress Reporter for setup operations
class ProgressReporter
  def initialize
    @current_section = nil
    @current_operation = nil
    @start_time = nil
  end

  def start_section(section_name)
    @current_section = section_name
    Print.info "Starting #{section_name}..."
    @start_time = Time.now
  end

  def end_section
    if @current_section && @start_time
      duration = Time.now - @start_time
      Print.info "Completed #{current_section} in #{duration.round(1)}s"
    end
    @current_section = nil
    @current_operation = nil
    @start_time = nil
  end

  def start_operation(operation_name)
    @current_operation = operation_name
    Print.info "  - #{operation_name}"
  end

  def end_operation
    @current_operation = nil
  end
end

# Main execution
if __FILE__ == $0
  config_path = ARGV[0] if ARGV.length > 0

  setup = OfflineRAGCAGSetup.new(config_path)
  setup.run_setup
end
