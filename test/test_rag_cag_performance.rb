#!/usr/bin/env ruby

require 'minitest/autorun'
require 'minitest/spec'
require 'benchmark'
require_relative 'test_helper'
require_relative '../rag_cag_manager'
require_relative '../print'

class RAGCAGPerformanceTest < Minitest::Test
  # Comprehensive cybersecurity training queries for performance testing
  CYBERSECURITY_QUERIES = [
    # MITRE ATT&CK Framework queries
    'What is T1059.001 Command and Scripting Interpreter PowerShell?',
    'Explain MITRE ATT&CK technique T1190 Exploit Public-Facing Application',
    'How does lateral movement T1021.002 SMB/Windows Admin Shares work?',
    'What are the mitigation strategies for T1548.002 Abuse Elevation Control Mechanism Bypass UAC?',
    'Describe the attack pattern T1055.001 Process Injection Dynamic-link Library Injection',
    'What is the difference between T1057 Process Discovery and T1082 System Information Discovery?',
    'How does T1566.001 Phishing Spearphishing Attachment work?',
    'Explain defense evasion technique T1027 Obfuscated Files or Information',
    'What are the indicators of compromise for T1053.005 Scheduled Task/Job Scheduled Task',
    'How does credential dumping T1003.001 OS Credential Dumping LSASS Memory work?',

    # Security tool usage questions
    'How do I use nmap to perform a comprehensive port scan?',
    'What are the best nmap options for service version detection?',
    'How can I use Wireshark to analyze network traffic for security incidents?',
    'What are the essential Metasploit commands for penetration testing?',
    'How do I configure Burp Suite for web application security testing?',
    'What are the most useful SQLMap commands for SQL injection testing?',
    'How can I use Nikto to scan web servers for vulnerabilities?',
    'What are the best practices for using John the Ripper for password cracking?',
    'How do I use Aircrack-ng for wireless security testing?',
    'What are the essential commands for using Hashcat for GPU-accelerated cracking?',

    # Network security concepts
    'What is the difference between TCP and UDP in network security?',
    'How does a man-in-the-middle attack work on wireless networks?',
    'What are the common network protocols and their security implications?',
    'How does DNSSEC protect against DNS spoofing attacks?',
    'What is the difference between stateful and stateless firewalls?',
    'How does network segmentation improve security posture?',
    'What are the best practices for securing network infrastructure?',
    'How does VLAN hopping attack work and how to prevent it?',
    'What is the role of intrusion detection systems in network security?',
    'How does SSL/TLS encryption protect network communications?',

    # Cryptography and encryption
    'What is the difference between symmetric and asymmetric encryption?',
    'How does RSA encryption work and what are its key sizes?',
    'What are the weaknesses of DES and why was AES developed?',
    'How does public key infrastructure (PKI) work?',
    'What is the difference between hashing and encryption?',
    'How does digital signature verification work?',
    'What are the best practices for key management in cryptography?',
    'How does elliptic curve cryptography improve security?',
    'What is the difference between block ciphers and stream ciphers?',
    'How does quantum computing threaten current cryptographic systems?',

    # Incident response procedures
    'What are the phases of the incident response lifecycle?',
    'How do you create an effective incident response plan?',
    'What are the key steps in digital evidence collection?',
    'How do you perform malware analysis during incident response?',
    'What are the best practices for containment and eradication?',
    'How do you conduct post-incident analysis and lessons learned?',
    'What tools are essential for incident response teams?',
    'How do you prioritize incidents based on severity?',
    'What are the legal considerations in incident response?',
    'How do you coordinate with law enforcement during security incidents?',

    # Vulnerability assessment
    'What is the difference between vulnerability scanning and penetration testing?',
    'How do you prioritize vulnerabilities using CVSS scores?',
    'What are the common vulnerability assessment methodologies?',
    'How do you conduct a comprehensive web application vulnerability assessment?',
    'What are the best practices for vulnerability management programs?',
    'How do you use Nessus for network vulnerability scanning?',
    'What is the difference between authenticated and unauthenticated scanning?',
    'How do you validate and remediate discovered vulnerabilities?',
    'What are the limitations of automated vulnerability scanners?',
    'How do you integrate vulnerability assessment into DevSecOps pipelines?',

    # Penetration testing techniques
    'What are the phases of a penetration testing engagement?',
    'How do you perform reconnaissance and information gathering?',
    'What are the common web application attack techniques?',
    'How do you exploit buffer overflow vulnerabilities?',
    'What are the best practices for privilege escalation?',
    'How do you perform social engineering penetration tests?',
    'What are the techniques for bypassing security controls?',
    'How do you document penetration testing findings?',
    'What are the ethical considerations in penetration testing?',
    'How do you perform post-exploitation activities safely?',

    # Security best practices
    'What are the essential security controls for modern organizations?',
    'How do you implement the principle of least privilege?',
    'What are the best practices for secure coding?',
    'How do you create effective security awareness training programs?',
    'What are the key components of a security operations center (SOC)?',
    'How do you implement defense-in-depth security architecture?',
    'What are the best practices for cloud security?',
    'How do you secure mobile devices in enterprise environments?',
    'What are the essential elements of a security policy framework?',
    'How do you measure the effectiveness of security controls?',

    # Additional advanced queries
    'What is zero-trust architecture and how does it work?',
    'How do threat hunting techniques differ from traditional security monitoring?',
    'What are the challenges in securing IoT devices?',
    'How does machine learning improve threat detection?',
    'What are the best practices for securing containerized applications?',
    'How do you implement secure software development lifecycle (SSDLC)?',
    'What is the role of deception technology in cybersecurity?',
    'How do you secure microservices architecture?',
    'What are the emerging threats in cloud-native environments?',
    'How does behavioral analytics improve security monitoring?',

    # Complex scenario-based queries
    'A user reports suspicious activity on their account. What investigation steps should you take?',
    'How would you respond to a ransomware attack on critical infrastructure?',
    'What steps would you take to secure a newly discovered web application vulnerability?',
    'How do you investigate a potential data breach in a cloud environment?',
    'What is your approach to securing a remote workforce during a pandemic?',
    'How would you handle a sophisticated APT attack targeting your organization?',
    'What are the steps to secure a compromised Active Directory environment?',
    'How do you respond to a DDoS attack against your web services?',
    'What investigation process would you follow for insider threat detection?',
    'How do you secure a supply chain against third-party risks?',

    # Tool-specific advanced queries
    'How do you use Volatility for memory forensics analysis?',
    'What are the advanced features of Kali Linux for penetration testing?',
    'How do you configure Snort for effective intrusion detection?',
    'What are the best practices for using ELK stack for security monitoring?',
    'How do you use OSQuery for endpoint security monitoring?',
    'What are the advanced techniques for using Splunk in security operations?',
    'How do you configure Suricata for network intrusion detection?',
    'What are the best practices for using OpenVAS for vulnerability management?',
    'How do you use MISP for threat intelligence sharing?',
    'What are the advanced features of Security Onion for security monitoring?',

    # Compliance and regulatory queries
    'What are the key requirements of GDPR for data protection?',
    'How do you achieve compliance with PCI DSS for payment processing?',
    'What are the security controls required by HIPAA?',
    'How do you implement NIST Cybersecurity Framework?',
    'What are the requirements for ISO 27001 certification?',
    'How do you comply with SOX requirements for IT security?',
    'What are the security considerations for CCPA compliance?',
    'How do you implement controls for FISMA compliance?',
    'What are the requirements for CMMC in defense contracting?',
    'How do you achieve compliance with industry-specific security standards?'
  ].freeze

  def setup
    @test_results = {
      rag: {
        response_times: [],
        memory_usage: [],
        load_times: [],
        result_lengths: [],
        success_count: 0,
        error_count: 0
      },
      cag: {
        response_times: [],
        memory_usage: [],
        load_times: [],
        result_lengths: [],
        success_count: 0,
        error_count: 0
      },
      unified: {
        response_times: [],
        memory_usage: [],
        load_times: [],
        result_lengths: [],
        success_count: 0,
        error_count: 0
      }
    }

    @performance_report = {
      test_metadata: {
        total_queries: CYBERSECURITY_QUERIES.length,
        test_date: Time.now.strftime('%Y-%m-%d %H:%M:%S'),
        ruby_version: RUBY_VERSION,
        platform: RUBY_PLATFORM
      },
      system_info: {},
      detailed_results: []
    }

    # Suppress print output during tests
    @old_stdout = $stdout
    @old_stderr = $stderr
    $stdout = StringIO.new
    $stderr = StringIO.new
  end

  def teardown
    $stdout = @old_stdout
    $stderr = @old_stderr
  end

  def test_rag_cag_performance_comparison
    puts "\n" + '=' * 80
    puts 'RAG vs CAG Performance Comparison Test'
    puts '=' * 80
    puts "Testing #{CYBERSECURITY_QUERIES.length} cybersecurity queries"
    puts "Test started at: #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"
    puts '=' * 80 + "\n"

    # Initialize managers
    rag_cag_manager = create_test_rag_cag_manager
    refute_nil rag_cag_manager, 'Failed to create RAGCAGManager'

    # Test initialization time
    init_time = Benchmark.realtime do
      assert rag_cag_manager.setup, 'Failed to setup RAGCAGManager'
      create_minimal_test_knowledge_base(rag_cag_manager)
    end

    puts "Initialization completed in #{init_time.round(3)} seconds"
    @performance_report[:system_info][:initialization_time] = init_time.round(3)

    # Get system information
    @performance_report[:system_info][:rag_enabled] = !rag_cag_manager.instance_variable_get(:@rag_manager).nil?
    @performance_report[:system_info][:cag_enabled] = !rag_cag_manager.instance_variable_get(:@cag_manager).nil?
    @performance_report[:system_info][:knowledge_base_stats] = rag_cag_manager.get_retrieval_stats

    # Test each query
    CYBERSECURITY_QUERIES.each_with_index do |query, index|
      test_query_performance(rag_cag_manager, query, index + 1)

      # Progress indicator
      print '.' if (index + 1) % 5 == 0
      puts "\nProgress: #{index + 1}/#{CYBERSECURITY_QUERIES.length}" if (index + 1) % 20 == 0
    end

    puts "\n" + '=' * 80
    puts 'Performance Testing Completed'
    puts '=' * 80

    # Generate comprehensive report
    generate_performance_report

    # Cleanup
    rag_cag_manager.cleanup

    puts 'Test completed successfully!'
  end

  private

  def create_minimal_test_knowledge_base(manager)
    # Create minimal test data for performance testing
    test_documents = [
      {
        id: 'test_doc_1',
        content: 'MITRE ATT&CK technique T1059.001 PowerShell is a command-line interface and scripting language used for execution.',
        source: 'test',
        metadata: { technique: 'T1059.001', category: 'execution' }
      },
      {
        id: 'test_doc_2',
        content: 'Nmap is a network scanning tool used for port scanning and service detection.',
        source: 'test',
        metadata: { tool: 'nmap', category: 'reconnaissance' }
      },
      {
        id: 'test_doc_3',
        content: 'SQL injection is a code injection technique that exploits vulnerabilities in database queries.',
        source: 'test',
        metadata: { technique: 'sql_injection', category: 'attack' }
      },
      {
        id: 'test_doc_4',
        content: 'AES encryption is a symmetric encryption algorithm used for secure data transmission.',
        source: 'test',
        metadata: { algorithm: 'aes', category: 'cryptography' }
      },
      {
        id: 'test_doc_5',
        content: 'Incident response involves preparation, detection, containment, eradication, and recovery phases.',
        source: 'test',
        metadata: { phase: 'incident_response', category: 'process' }
      }
    ]

    test_triplets = [
      { subject: 'PowerShell', relationship: 'IS_A', object: 'Command-Line Interface' },
      { subject: 'PowerShell', relationship: 'HAS_TECHNIQUE_ID', object: 'T1059.001' },
      { subject: 'Nmap', relationship: 'IS_A', object: 'Network Scanner' },
      { subject: 'SQL Injection', relationship: 'IS_A', object: 'Attack Technique' },
      { subject: 'AES', relationship: 'IS_A', object: 'Encryption Algorithm' },
      { subject: 'Incident Response', relationship: 'HAS_PHASE', object: 'Detection' },
      { subject: 'Incident Response', relationship: 'HAS_PHASE', object: 'Containment' },
      { subject: 'MITRE ATT&CK', relationship: 'INCLUDES', object: 'T1059.001' }
    ]

    # Add RAG documents
    if manager.instance_variable_get(:@rag_manager)
      manager.instance_variable_get(:@rag_manager).add_knowledge_base('performance_test', test_documents)
    end

    # Add CAG triplets
    if manager.instance_variable_get(:@cag_manager)
      manager.instance_variable_get(:@cag_manager).create_knowledge_base_from_triplets(test_triplets)
    end

    puts "Created minimal test knowledge base with #{test_documents.length} documents and #{test_triplets.length} triplets"
  end

  def create_test_rag_cag_manager
    # RAG configuration with offline ChromaDB
    rag_config = {
      vector_db: {
        provider: 'chromadb',
        host: 'localhost',
        port: 8000,
        collection_name: 'performance_test_rag'
      },
      embedding_service: {
        provider: 'mock', # Use mock for consistent testing
        model: 'mock-embed-model',
        embedding_dimension: 384
      },
      rag_settings: {
        max_results: 5,
        similarity_threshold: 0.7,
        enable_caching: false # Disable caching for accurate performance measurement
      }
    }

    # CAG configuration with in-memory graph
    cag_config = {
      knowledge_graph: {
        provider: 'in_memory',
        graph_name: 'performance_test_cag'
      },
      entity_extractor: {
        provider: 'rule_based'
      },
      cag_settings: {
        max_context_depth: 2,
        max_context_nodes: 20,
        enable_caching: false # Disable caching for accurate performance measurement
      }
    }

    # Unified configuration - disable knowledge sources for faster testing
    unified_config = {
      enable_rag: true,
      enable_cag: true,
      rag_weight: 0.6,
      cag_weight: 0.4,
      max_context_length: 4000,
      knowledge_base_name: 'performance_test',
      enable_caching: false, # Disable caching for accurate performance measurement
      auto_initialization: false, # We'll initialize manually
      enable_knowledge_sources: false # Disable knowledge sources for faster testing
    }

    RAGCAGManager.new(rag_config, cag_config, unified_config)
  end

  def test_query_performance(manager, query, query_number)
    query_result = {
      query_number: query_number,
      query: query[0..100] + (query.length > 100 ? '...' : ''),
      category: categorize_query(query)
    }

    # Test RAG-only performance
    if manager.instance_variable_get(:@rag_manager)
      rag_result = test_rag_performance(manager, query)
      query_result[:rag] = rag_result
      @test_results[:rag][:response_times] << rag_result[:response_time]
      @test_results[:rag][:memory_usage] << rag_result[:memory_usage]
      @test_results[:rag][:result_lengths] << rag_result[:result_length]
      rag_result[:success] ? @test_results[:rag][:success_count] += 1 : @test_results[:rag][:error_count] += 1
    end

    # Test CAG-only performance
    if manager.instance_variable_get(:@cag_manager)
      cag_result = test_cag_performance(manager, query)
      query_result[:cag] = cag_result
      @test_results[:cag][:response_times] << cag_result[:response_time]
      @test_results[:cag][:memory_usage] << cag_result[:memory_usage]
      @test_results[:cag][:result_lengths] << cag_result[:result_length]
      cag_result[:success] ? @test_results[:cag][:success_count] += 1 : @test_results[:cag][:error_count] += 1
    end

    # Test unified RAG+CAG performance
    unified_result = test_unified_performance(manager, query)
    query_result[:unified] = unified_result
    @test_results[:unified][:response_times] << unified_result[:response_time]
    @test_results[:unified][:memory_usage] << unified_result[:memory_usage]
    @test_results[:unified][:result_lengths] << unified_result[:result_length]
    unified_result[:success] ? @test_results[:unified][:success_count] += 1 : @test_results[:unified][:error_count] += 1

    @performance_report[:detailed_results] << query_result
  end

  def test_rag_performance(manager, query)
    result = { response_time: 0, memory_usage: 0, result_length: 0, success: false, error: nil }

    begin
      # Measure memory before
      memory_before = get_memory_usage

      # Measure response time (excluding LLM inference)
      response_time = Benchmark.realtime do
        rag_context = manager.instance_variable_get(:@rag_manager).retrieve_relevant_context(
          query, 'performance_test', 5
        )
        result[:result_length] = rag_context ? rag_context.length : 0
      end

      # Measure memory after
      memory_after = get_memory_usage
      result[:memory_usage] = memory_after - memory_before
      result[:response_time] = response_time
      result[:success] = true
    rescue StandardError => e
      result[:error] = e.message
      result[:success] = false
    end

    result
  end

  def test_cag_performance(manager, query)
    result = { response_time: 0, memory_usage: 0, result_length: 0, success: false, error: nil }

    begin
      # Measure memory before
      memory_before = get_memory_usage

      # Measure response time (excluding LLM inference)
      response_time = Benchmark.realtime do
        cag_context = manager.instance_variable_get(:@cag_manager).get_context_for_query(
          query, 2, 20
        )
        result[:result_length] = cag_context ? cag_context.length : 0
      end

      # Measure memory after
      memory_after = get_memory_usage
      result[:memory_usage] = memory_after - memory_before
      result[:response_time] = response_time
      result[:success] = true
    rescue StandardError => e
      result[:error] = e.message
      result[:success] = false
    end

    result
  end

  def test_unified_performance(manager, query)
    result = { response_time: 0, memory_usage: 0, result_length: 0, success: false, error: nil }

    begin
      # Measure memory before
      memory_before = get_memory_usage

      # Measure response time (excluding LLM inference)
      response_time = Benchmark.realtime do
        unified_context = manager.get_enhanced_context(query, {
                                                         include_rag_context: true,
                                                         include_cag_context: true,
                                                         max_rag_results: 5,
                                                         max_cag_depth: 2,
                                                         max_cag_nodes: 20
                                                       })
        result[:result_length] = unified_context ? unified_context.length : 0
      end

      # Measure memory after
      memory_after = get_memory_usage
      result[:memory_usage] = memory_after - memory_before
      result[:response_time] = response_time
      result[:success] = true
    rescue StandardError => e
      result[:error] = e.message
      result[:success] = false
    end

    result
  end

  def categorize_query(query)
    categories = {
      'MITRE ATT&CK' => /MITRE|T\d+/,
      'Security Tools' => /nmap|wireshark|metasploit|burp|sqlmap|nikto|john|aircrack|hashcat/,
      'Network Security' => /network|tcp|udp|firewall|dns|vlan|wireless/,
      'Cryptography' => /encryption|rsa|aes|des|hash|cryptographic|ssl|tls/,
      'Incident Response' => /incident|response|forensics|malware|containment|eradication/,
      'Vulnerability Assessment' => /vulnerability|scanning|nessus|cvss|penetration/,
      'Security Best Practices' => /best practices|security controls|policy|framework/,
      'Compliance' => /GDPR|PCI|HIPAA|NIST|ISO|SOX|compliance/
    }

    categories.each do |category, pattern|
      return category if query.match?(pattern)
    end

    'General Security'
  end

  def get_memory_usage
    # Simple memory usage measurement in MB
    GC.start # Force garbage collection for more accurate measurement
    `ps -o rss= -p #{Process.pid}`.to_i / 1024.0
  rescue StandardError
    0.0
  end

  def calculate_statistics(values)
    return {} if values.empty?

    sorted = values.sort
    {
      count: values.length,
      mean: (values.sum / values.length).round(3),
      median: sorted[sorted.length / 2].round(3),
      min: sorted.first.round(3),
      max: sorted.last.round(3),
      p95: sorted[(sorted.length * 0.95).to_i].round(3),
      p99: sorted[(sorted.length * 0.99).to_i].round(3),
      std_dev: calculate_std_dev(values).round(3)
    }
  end

  def calculate_std_dev(values)
    return 0 if values.length < 2

    mean = values.sum / values.length.to_f
    variance = values.sum { |v| (v - mean)**2 } / (values.length - 1).to_f
    Math.sqrt(variance)
  end

  def generate_performance_report
    puts "\n" + '=' * 80
    puts 'PERFORMANCE COMPARISON REPORT'
    puts '=' * 80

    # Overall statistics
    puts "\n1. OVERALL PERFORMANCE STATISTICS"
    puts '-' * 50

    %i[rag cag unified].each do |system|
      next if @test_results[system][:response_times].empty?

      puts "\n#{system.to_s.upcase} System:"
      stats = calculate_statistics(@test_results[system][:response_times])
      memory_stats = calculate_statistics(@test_results[system][:memory_usage])

      puts "  Success Rate: #{@test_results[system][:success_count]}/#{@test_results[system][:success_count] + @test_results[system][:error_count]} (#{(@test_results[system][:success_count].to_f / (@test_results[system][:success_count] + @test_results[system][:error_count]) * 100).round(1)}%)"
      puts '  Response Time Statistics:'
      puts "    Mean: #{stats[:mean]}s"
      puts "    Median: #{stats[:median]}s"
      puts "    Min: #{stats[:min]}s"
      puts "    Max: #{stats[:max]}s"
      puts "    95th percentile: #{stats[:p95]}s"
      puts "    99th percentile: #{stats[:p99]}s"
      puts "    Std Dev: #{stats[:std_dev]}s"

      puts '  Memory Usage Statistics:'
      puts "    Mean: #{memory_stats[:mean]}MB"
      puts "    Median: #{memory_stats[:median]}MB"
      puts "    Max: #{memory_stats[:max]}MB"

      length_stats = calculate_statistics(@test_results[system][:result_lengths])
      puts '  Result Length Statistics:'
      puts "    Mean: #{length_stats[:mean]} characters"
      puts "    Median: #{length_stats[:median]} characters"
    end

    # Performance comparison table
    puts "\n2. PERFORMANCE COMPARISON TABLE"
    puts '-' * 50
    puts format('%-12s %-12s %-12s %-12s %-12s', 'Metric', 'RAG', 'CAG', 'Unified', 'Winner')
    puts '-' * 60

    # Compare mean response times
    rag_mean = calculate_statistics(@test_results[:rag][:response_times])[:mean] || Float::INFINITY
    cag_mean = calculate_statistics(@test_results[:cag][:response_times])[:mean] || Float::INFINITY
    unified_mean = calculate_statistics(@test_results[:unified][:response_times])[:mean] || Float::INFINITY

    fastest = [rag_mean, cag_mean, unified_mean].min
    winner = if fastest == rag_mean
               'RAG'
             else
               (fastest == cag_mean ? 'CAG' : 'Unified')
             end

    puts format('%-12s %-12.3f %-12.3f %-12.3f %-12s', 'Mean Time (s)', rag_mean, cag_mean, unified_mean, winner)

    # Compare memory usage
    rag_mem = calculate_statistics(@test_results[:rag][:memory_usage])[:mean] || Float::INFINITY
    cag_mem = calculate_statistics(@test_results[:cag][:memory_usage])[:mean] || Float::INFINITY
    unified_mem = calculate_statistics(@test_results[:unified][:memory_usage])[:mean] || Float::INFINITY

    lowest_mem = [rag_mem, cag_mem, unified_mem].min
    mem_winner = if lowest_mem == rag_mem
                   'RAG'
                 else
                   (lowest_mem == cag_mem ? 'CAG' : 'Unified')
                 end

    puts format('%-12s %-12.3f %-12.3f %-12.3f %-12s', 'Mean Mem (MB)', rag_mem, cag_mem, unified_mem, mem_winner)

    # Compare success rates
    rag_success = begin
      @test_results[:rag][:success_count].to_f / (@test_results[:rag][:success_count] + @test_results[:rag][:error_count]) * 100
    rescue StandardError
      0
    end
    cag_success = begin
      @test_results[:cag][:success_count].to_f / (@test_results[:cag][:success_count] + @test_results[:cag][:error_count]) * 100
    rescue StandardError
      0
    end
    unified_success = begin
      @test_results[:unified][:success_count].to_f / (@test_results[:unified][:success_count] + @test_results[:unified][:error_count]) * 100
    rescue StandardError
      0
    end

    highest_success = [rag_success, cag_success, unified_success].max
    success_winner = if highest_success == rag_success
                       'RAG'
                     else
                       (highest_success == cag_success ? 'CAG' : 'Unified')
                     end

    puts format('%-12s %-12.1f %-12.1f %-12.1f %-12s', 'Success (%)', rag_success, cag_success, unified_success,
                success_winner)

    # Category-based analysis
    puts "\n3. CATEGORY-BASED PERFORMANCE ANALYSIS"
    puts '-' * 50

    categories = @performance_report[:detailed_results].map { |r| r[:category] }.uniq
    categories.each do |category|
      puts "\n#{category}:"
      category_results = @performance_report[:detailed_results].select { |r| r[:category] == category }

      %i[rag cag unified].each do |system|
        times = category_results.map { |r| r[system] ? r[system][:response_time] : nil }.compact
        next if times.empty?

        stats = calculate_statistics(times)
        puts "  #{system.to_s.upcase}: Mean #{stats[:mean]}s, Median #{stats[:median]}s"
      end
    end

    # Text-based performance charts
    puts "\n4. PERFORMANCE VISUALIZATION"
    puts '-' * 50

    # Response time distribution chart
    puts "\nResponse Time Distribution (seconds):"
    puts "RAG:    #{create_bar_chart(@test_results[:rag][:response_times], 50)}"
    puts "CAG:    #{create_bar_chart(@test_results[:cag][:response_times], 50)}"
    puts "Unified: #{create_bar_chart(@test_results[:unified][:response_times], 50)}"

    # Memory usage distribution chart
    puts "\nMemory Usage Distribution (MB):"
    puts "RAG:    #{create_bar_chart(@test_results[:rag][:memory_usage], 10)}"
    puts "CAG:    #{create_bar_chart(@test_results[:cag][:memory_usage], 10)}"
    puts "Unified: #{create_bar_chart(@test_results[:unified][:memory_usage], 10)}"

    # Recommendations
    puts "\n5. RECOMMENDATIONS"
    puts '-' * 50

    recommendations = generate_recommendations
    recommendations.each_with_index do |rec, index|
      puts "#{index + 1}. #{rec}"
    end

    # Save detailed report to file
    save_detailed_report

    puts "\n" + '=' * 80
    puts 'REPORT GENERATION COMPLETED'
    puts "Detailed report saved to: test/performance_report_#{Time.now.strftime('%Y%m%d_%H%M%S')}.json"
    puts '=' * 80
  end

  def create_bar_chart(values, max_scale)
    return 'No data' if values.empty?

    stats = calculate_statistics(values)
    mean = stats[:mean]
    max_val = stats[:max]

    # Handle NaN or infinite values
    return 'Invalid data' if mean.nan? || mean.infinite? || max_val.nan? || max_val.infinite? || max_val == 0

    # Create a simple text bar chart
    bar_length = (mean / max_val * max_scale).to_i
    bar = '█' * bar_length + '░' * (max_scale - bar_length)
    "#{bar} #{mean.round(3)}s (max: #{max_val.round(3)}s)"
  end

  def generate_recommendations
    recommendations = []

    rag_mean = calculate_statistics(@test_results[:rag][:response_times])[:mean] || Float::INFINITY
    cag_mean = calculate_statistics(@test_results[:cag][:response_times])[:mean] || Float::INFINITY
    unified_mean = calculate_statistics(@test_results[:unified][:response_times])[:mean] || Float::INFINITY

    rag_success = begin
      @test_results[:rag][:success_count].to_f / (@test_results[:rag][:success_count] + @test_results[:rag][:error_count]) * 100
    rescue StandardError
      0
    end
    cag_success = begin
      @test_results[:cag][:success_count].to_f / (@test_results[:cag][:success_count] + @test_results[:cag][:error_count]) * 100
    rescue StandardError
      0
    end
    unified_success = begin
      @test_results[:unified][:success_count].to_f / (@test_results[:unified][:success_count] + @test_results[:unified][:error_count]) * 100
    rescue StandardError
      0
    end

    # Performance-based recommendations
    if rag_mean < cag_mean && rag_mean < unified_mean
      recommendations << "RAG shows the best average response time (#{rag_mean.round(3)}s). Consider using RAG for latency-sensitive applications."
    elsif cag_mean < rag_mean && cag_mean < unified_mean
      recommendations << "CAG shows the best average response time (#{cag_mean.round(3)}s). Consider using CAG for performance-critical scenarios."
    else
      recommendations << 'Unified approach provides balanced performance. Use when both document retrieval and entity relationships are important.'
    end

    # Reliability-based recommendations
    if rag_success > 95
      recommendations << "RAG demonstrates high reliability (#{rag_success.round(1)}% success rate). Suitable for production environments."
    end

    if cag_success > 95
      recommendations << "CAG demonstrates high reliability (#{cag_success.round(1)}% success rate). Suitable for production environments."
    end

    if unified_success > 95
      recommendations << "Unified approach demonstrates high reliability (#{unified_success.round(1)}% success rate). Most robust option."
    end

    # Memory usage recommendations
    rag_mem = calculate_statistics(@test_results[:rag][:memory_usage])[:mean] || 0
    cag_mem = calculate_statistics(@test_results[:cag][:memory_usage])[:mean] || 0
    unified_mem = calculate_statistics(@test_results[:unified][:memory_usage])[:mean] || 0

    if rag_mem < cag_mem && rag_mem < unified_mem
      recommendations << "RAG has the lowest memory footprint (#{rag_mem.round(3)}MB). Best for resource-constrained environments."
    elsif cag_mem < rag_mem && cag_mem < unified_mem
      recommendations << "CAG has the lowest memory footprint (#{cag_mem.round(3)}MB). Best for resource-constrained environments."
    end

    # General recommendations
    recommendations << 'Consider implementing caching mechanisms to improve response times for repeated queries.'
    recommendations << 'Monitor memory usage in production and implement appropriate scaling strategies.'
    recommendations << 'Use A/B testing to validate performance improvements in real-world scenarios.'
    recommendations << 'Consider query routing based on content type for optimal performance.'

    recommendations
  end

  def save_detailed_report
    require 'json'

    report_data = {
      performance_report: @performance_report,
      test_results: @test_results,
      statistics: {
        rag: {
          response_times: calculate_statistics(@test_results[:rag][:response_times]),
          memory_usage: calculate_statistics(@test_results[:rag][:memory_usage]),
          result_lengths: calculate_statistics(@test_results[:rag][:result_lengths])
        },
        cag: {
          response_times: calculate_statistics(@test_results[:cag][:response_times]),
          memory_usage: calculate_statistics(@test_results[:cag][:memory_usage]),
          result_lengths: calculate_statistics(@test_results[:cag][:result_lengths])
        },
        unified: {
          response_times: calculate_statistics(@test_results[:unified][:response_times]),
          memory_usage: calculate_statistics(@test_results[:unified][:memory_usage]),
          result_lengths: calculate_statistics(@test_results[:unified][:result_lengths])
        }
      }
    }

    timestamp = Time.now.strftime('%Y%m%d_%H%M%S')
    filename = "test/performance_report_#{timestamp}.json"

    # Ensure test directory exists
    Dir.mkdir('test') unless Dir.exist?('test')

    File.write(filename, JSON.pretty_generate(report_data))
    filename
  end
end
