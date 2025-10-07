#!/usr/bin/env ruby

# CAG Knowledge Initialization and Testing Script
# This script tests the CAG system with proper knowledge base initialization

require_relative '../rag_cag_manager.rb'
require_relative '../print.rb'
require_relative '../knowledge_bases/mitre_attack_knowledge.rb'

puts "CAG Knowledge Initialization and Testing"
puts "=" * 50

def test_mitre_knowledge_availability
  puts "\n1. Testing MITRE ATT&CK Knowledge Availability"
  puts "-" * 45

  begin
    rag_docs = MITREAttackKnowledge.to_rag_documents
    cag_triplets = MITREAttackKnowledge.to_cag_triplets

    puts "✓ MITRE ATT&CK knowledge loaded successfully"
    puts "  - RAG documents: #{rag_docs.length}"
    puts "  - CAG triplets: #{cag_triplets.length}"

    # Show some examples
    if rag_docs.length > 0
      puts "\nSample RAG document:"
      sample_doc = rag_docs.first
      puts "  ID: #{sample_doc[:id]}"
      puts "  Type: #{sample_doc[:metadata][:type]}"
      puts "  Content preview: #{sample_doc[:content][0..100]}..."
    end

    if cag_triplets.length > 0
      puts "\nSample CAG triplets:"
      cag_triplets.first(3).each do |triplet|
        puts "  #{triplet[:subject]} --#{triplet[:relationship]}--> #{triplet[:object]}"
      end
    end

    return rag_docs, cag_triplets

  rescue => e
    puts "✗ Failed to load MITRE ATT&CK knowledge: #{e.message}"
    puts e.backtrace
    return nil, nil
  end
end

def test_cag_initialization(cag_triplets)
  puts "\n2. Testing CAG Manager Initialization"
  puts "-" * 40

  begin
    cag_config = {
      knowledge_graph: {
        provider: 'in_memory'
      },
      entity_extractor: {
        provider: 'rule_based'
      },
      cag_settings: {
        max_context_depth: 3,
        max_context_nodes: 25,
        enable_caching: true
      }
    }

    manager = RAGCAGManager.new({}, cag_config, {
      enable_rag: false,
      enable_cag: true,
      auto_initialization: true
    })

    if manager.setup
      puts "✓ CAG Manager initialized successfully"

      # Load knowledge into CAG
      if manager.instance_variable_get(:@cag_manager) && cag_triplets
        cag_manager = manager.instance_variable_get(:@cag_manager)
        if cag_manager.create_knowledge_base_from_triplets(cag_triplets)
          puts "✓ CAG knowledge base loaded successfully"
          puts "  - Triplets loaded: #{cag_triplets.length}"
        else
          puts "✗ Failed to load CAG knowledge base"
          return nil
        end
      end

      return manager
    else
      puts "✗ Failed to initialize CAG Manager"
      return nil
    end

  rescue => e
    puts "✗ CAG initialization failed: #{e.message}"
    puts e.backtrace
    return nil
  end
end

def test_entity_extraction(manager)
  puts "\n3. Testing Entity Extraction"
  puts "-" * 30

  test_messages = [
    "The attack came from 192.168.1.100 using http://malicious.com/malware.exe",
    "Found file suspicious.dll with hash 1a2b3c4d5e6f7890abcdef1234567890abcdef1234",
    "Attacker used Mimikatz to dump credentials from LSASS",
    "Phishing email from attacker@evil.com containing malicious link",
    "Connected to C2 server on port 4444"
  ]

  test_messages.each_with_index do |message, i|
    puts "\nTest #{i+1}: #{message}"
    entities = manager.extract_entities(message)

    if entities && !entities.empty?
      puts "  ✓ Extracted #{entities.length} entities:"
      entities.each do |entity|
        puts "    - #{entity[:type].upcase}: #{entity[:value]}"
      end
    else
      puts "  ✗ No entities extracted"
    end
  end
end

def test_context_retrieval(manager)
  puts "\n4. Testing Context Retrieval"
  puts "-" * 30

  test_queries = [
    "What is Mimikatz?",
    "Tell me about credential dumping techniques",
    "How does phishing work?",
    "What tools are used for network scanning?",
    "Explain lateral movement techniques",
    "What mitigations exist for ransomware?"
  ]

  test_queries.each_with_index do |query, i|
    puts "\nQuery #{i+1}: #{query}"

    # Test CAG context retrieval
    context = manager.get_enhanced_context(query)

    if context && !context.strip.empty?
      puts "  ✓ Context retrieved (#{context.length} characters)"

      # Show preview
      preview = context.length > 200 ? context[0..200] + "..." : context
      puts "  Preview: #{preview.gsub(/\n/, ' ')}"
    else
      puts "  ✗ No context retrieved"
    end
  end
end

def test_related_entities(manager)
  puts "\n5. Testing Related Entity Discovery"
  puts "-" * 38

  test_entities = [
    "Mimikatz",
    "Phishing",
    "Ransomware",
    "Metasploit Framework",
    "Endpoint Detection and Response"
  ]

  test_entities.each do |entity|
    puts "\nFinding related entities for: #{entity}"

    related = manager.find_related_entities(entity)

    if related && !related.empty?
      puts "  ✓ Found #{related.length} related entities:"
      related.first(5).each do |rel_entity|
        name = rel_entity.dig(:properties, 'name') || rel_entity[:id]
        rel_type = rel_entity[:relationship_type] || 'RELATED'
        puts "    - #{name} (#{rel_type})"
      end
    else
      puts "  ✗ No related entities found"
    end
  end
end

def test_knowledge_graph_stats(manager)
  puts "\n6. Testing Knowledge Graph Statistics"
  puts "-" * 40

  stats = manager.get_retrieval_stats

  if stats
    puts "✓ Statistics retrieved:"
    puts "  - Initialized: #{stats[:initialized]}"
    puts "  - RAG Enabled: #{stats[:rag_enabled]}"
    puts "  - CAG Enabled: #{stats[:cag_enabled]}"
    puts "  - Cache Size: #{stats[:cache_size]}"

    if stats[:cag_graph_stats]
      puts "  - Graph Nodes: #{stats[:cag_graph_stats][:node_count]}"
      puts "  - Graph Relationships: #{stats[:cag_graph_stats][:relationship_count]}"
      puts "  - Graph Labels: #{stats[:cag_graph_stats][:labels_count]}"
    end
  else
    puts "✗ Failed to retrieve statistics"
  end
end

def test_specific_scenario(manager)
  puts "\n7. Testing Specific Attack Scenario"
  puts "-" * 38

  scenario = "The attack came from 192.168.1.100 using http://malicious.com/malware.exe"

  puts "Scenario: #{scenario}"

  # Extract entities
  entities = manager.extract_entities(scenario)
  puts "\nExtracted entities: #{entities.length}"
  entities.each { |e| puts "  - #{e[:type]}: #{e[:value]}" }

  # Get enhanced context
  context = manager.get_enhanced_context(scenario)

  if context && !context.strip.empty?
    puts "\n✓ Enhanced context retrieved (#{context.length} characters)"

    # Check for relevant knowledge
    relevant_terms = ["malware", "attack", "malicious", "tool", "technique"]
    found_relevant = relevant_terms.any? { |term| context.downcase.include?(term) }

    if found_relevant
      puts "✓ Context contains relevant cybersecurity information"
    else
      puts "⚠ Context may not contain relevant information"
    end

    puts "\nFull context:"
    puts context
  else
    puts "✗ No enhanced context retrieved"
  end
end

def main
  begin
    # Test MITRE knowledge availability
    rag_docs, cag_triplets = test_mitre_knowledge_availability

    if !rag_docs || !cag_triplets
      puts "\n❌ Cannot proceed without MITRE knowledge"
      exit 1
    end

    # Test CAG initialization
    manager = test_cag_initialization(cag_triplets)

    if !manager
      puts "\n❌ Cannot proceed without CAG manager"
      exit 1
    end

    # Run comprehensive tests
    test_entity_extraction(manager)
    test_context_retrieval(manager)
    test_related_entities(manager)
    test_knowledge_graph_stats(manager)
    test_specific_scenario(manager)

    # Cleanup
    puts "\n8. Cleanup"
    puts "-" * 10
    manager.cleanup
    puts "✓ Cleanup completed"

    puts "\n" + "=" * 50
    puts "✅ CAG Knowledge Testing Completed Successfully!"
    puts "=" * 50

  rescue => e
    puts "\n❌ Test failed with error: #{e.message}"
    puts e.backtrace
    exit 1
  end
end

# Run the test
if __FILE__ == $0
  main
end
