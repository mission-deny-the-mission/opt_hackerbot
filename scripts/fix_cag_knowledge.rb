#!/usr/bin/env ruby

# Fix CAG Knowledge Initialization Script
# This script properly initializes the CAG system with MITRE ATT&CK knowledge

require_relative '../rag_cag_manager.rb'
require_relative '../print.rb'
require_relative '../knowledge_bases/mitre_attack_knowledge.rb'

puts "Fixing CAG Knowledge Initialization"
puts "=" * 40

def initialize_cag_with_knowledge
  puts "\n1. Loading MITRE ATT&CK knowledge..."

  begin
    rag_docs = MITREAttackKnowledge.to_rag_documents
    cag_triplets = MITREAttackKnowledge.to_cag_triplets

    puts "✓ Loaded #{rag_docs.length} RAG documents"
    puts "✓ Loaded #{cag_triplets.length} CAG triplets"

    return rag_docs, cag_triplets
  rescue => e
    puts "✗ Failed to load MITRE knowledge: #{e.message}"
    return nil, nil
  end
end

def create_cag_manager(cag_triplets)
  puts "\n2. Creating CAG Manager..."

  begin
    # Configuration for CAG only
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

    unified_config = {
      enable_rag: false,
      enable_cag: true,
      auto_initialization: true,
      knowledge_base_name: 'cybersecurity'
    }

    manager = RAGCAGManager.new({}, cag_config, unified_config)

    if manager.setup
      puts "✓ CAG Manager initialized successfully"

      # Load knowledge into the graph
      if cag_triplets && !cag_triplets.empty?
        cag_manager = manager.instance_variable_get(:@cag_manager)
        if cag_manager && cag_manager.create_knowledge_base_from_triplets(cag_triplets)
          puts "✓ CAG knowledge base loaded with #{cag_triplets.length} triplets"
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
    puts "✗ CAG Manager creation failed: #{e.message}"
    puts e.backtrace.first(5)
    return nil
  end
end

def test_entity_extraction(manager)
  puts "\n3. Testing entity extraction..."

  test_message = "The attack came from 192.168.1.100 using http://malicious.com/malware.exe"

  begin
    entities = manager.extract_entities(test_message)

    if entities && !entities.empty?
      puts "✓ Extracted #{entities.length} entities:"
      entities.each do |entity|
        puts "  - #{entity[:type].upcase}: #{entity[:value]}"
      end
      return entities
    else
      puts "✗ No entities extracted"
      return []
    end
  rescue => e
    puts "✗ Entity extraction failed: #{e.message}"
    return []
  end
end

def test_context_expansion(manager, entities)
  puts "\n4. Testing context expansion..."

  if entities.empty?
    puts "⚠ No entities to expand context with"
    return ""
  end

  begin
    context_nodes = manager.expand_context_with_entities(entities)

    if context_nodes && !context_nodes.empty?
      puts "✓ Expanded context to #{context_nodes.length} nodes"

      context_nodes.first(3).each do |node|
        name = node.dig(:properties, 'name') || node[:id]
        puts "  - Found node: #{name}"
      end

      # Generate context text
      context_parts = []
      context_nodes.each do |node|
        name = node.dig(:properties, 'name') || node[:id]
        labels = node[:labels] || []
        context_parts << "#{labels.join(', ')}: #{name}"
      end

      return context_parts.join("\n")
    else
      puts "✗ No context nodes found"
      return ""
    end
  rescue => e
    puts "✗ Context expansion failed: #{e.message}"
    return ""
  end
end

def test_enhanced_context(manager)
  puts "\n5. Testing enhanced context retrieval..."

  test_queries = [
    "What is known about the IP address 192.168.1.100?",
    "Tell me about malware downloads from malicious domains",
    "What tools are used for credential dumping?",
    "Explain phishing attacks and mitigations"
  ]

  test_queries.each_with_index do |query, i|
    puts "\nQuery #{i+1}: #{query}"

    begin
      context = manager.get_enhanced_context(query)

      if context && !context.strip.empty?
        puts "✓ Retrieved context (#{context.length} characters)"

        # Show preview
        preview = context.length > 200 ? context[0..200] + "..." : context
        puts "  Preview: #{preview.gsub(/\n/, ' ')}"
      else
        puts "✗ No context retrieved"
      end
    rescue => e
      puts "✗ Context retrieval failed: #{e.message}"
    end
  end
end

def get_graph_statistics(manager)
  puts "\n6. Getting graph statistics..."

  begin
    stats = manager.get_retrieval_stats

    if stats
      puts "✓ Statistics retrieved:"
      puts "  - Initialized: #{stats[:initialized]}"
      puts "  - CAG Enabled: #{stats[:cag_enabled]}"
      puts "  - Cache Size: #{stats[:cache_size]}"

      if stats[:cag_graph_stats]
        puts "  - Graph Nodes: #{stats[:cag_graph_stats][:node_count]}"
        puts "  - Graph Relationships: #{stats[:cag_graph_stats][:relationship_count]}"
        puts "  - Graph Labels: #{stats[:cag_graph_stats][:labels_count]}"
      end

      return stats
    else
      puts "✗ Failed to retrieve statistics"
      return nil
    end
  rescue => e
    puts "✗ Statistics retrieval failed: #{e.message}"
    return nil
  end
end

def test_specific_attack_scenario(manager)
  puts "\n7. Testing specific attack scenario..."

  scenario = "The attack came from 192.168.1.100 using http://malicious.com/malware.exe"
  puts "Scenario: #{scenario}"

  # Step 1: Extract entities
  entities = manager.extract_entities(scenario)
  puts "\nExtracted entities: #{entities.length}"
  entities.each { |e| puts "  - #{e[:type]}: #{e[:value]}" }

  # Step 2: Get enhanced context
  context = manager.get_enhanced_context(scenario)

  if context && !context.strip.empty?
    puts "\n✓ Enhanced context retrieved (#{context.length} characters)"

    # Check if the context contains relevant information
    relevant_keywords = ["attack", "malware", "tool", "technique", "mitigation", "credential"]
    found_keywords = relevant_keywords.select { |kw| context.downcase.include?(kw) }

    if !found_keywords.empty?
      puts "✓ Context contains relevant keywords: #{found_keywords.join(', ')}"
    else
      puts "⚠ Context may not contain relevant information"
    end

    puts "\nFull context:"
    puts "-" * 20
    puts context
    puts "-" * 20
  else
    puts "✗ No enhanced context retrieved"
  end
end

def main
  begin
    # Step 1: Initialize knowledge
    rag_docs, cag_triplets = initialize_cag_with_knowledge

    if !cag_triplets || cag_triplets.empty?
      puts "\n❌ Cannot proceed without CAG triplets"
      exit 1
    end

    # Step 2: Create CAG manager
    manager = create_cag_manager(cag_triplets)

    if !manager
      puts "\n❌ Cannot proceed without CAG manager"
      exit 1
    end

    # Step 3: Run tests
    entities = test_entity_extraction(manager)
    test_context_expansion(manager, entities)
    test_enhanced_context(manager)
    get_graph_statistics(manager)
    test_specific_attack_scenario(manager)

    # Step 4: Cleanup
    puts "\n8. Cleaning up..."
    manager.cleanup
    puts "✓ Cleanup completed"

    puts "\n" + "=" * 40
    puts "✅ CAG Knowledge Fix Completed!"
    puts "The CAG system should now have proper knowledge loaded."
    puts "=" * 40

  rescue => e
    puts "\n❌ Fix failed with error: #{e.message}"
    puts e.backtrace
    exit 1
  end
end

# Run the fix
if __FILE__ == $0
  main
end

# Additional helper method to map extracted entities to cybersecurity concepts
def map_entities_to_cybersecurity_concepts(entities)
  entity_mappings = {
    # IP addresses -> Network scanning concepts
    'ip_address' => ['Network Scanning', 'Reconnaissance', 'Command and Control'],
    # URLs -> Malware delivery concepts
    'url' => ['Malware Delivery', 'Phishing', 'Drive-by Compromise', 'Exploit Public-Facing Application'],
    # Hashes -> Malware analysis concepts
    'hash' => ['Malware Analysis', 'File Hashing', 'Forensic Analysis'],
    # Filenames -> Malware concepts
    'filename' => ['Malware', 'Trojan', 'Backdoor', 'Executable'],
    # Ports -> Network concepts
    'port' => ['Network Scanning', 'Command and Control', 'Lateral Movement'],
    # Emails -> Phishing concepts
    'email' => ['Phishing', 'Spearphishing', 'Social Engineering']
  }

  mapped_concepts = []
  entities.each do |entity|
    type = entity[:type]
    if entity_mappings[type]
      mapped_concepts.concat(entity_mappings[type])
    end
  end

  mapped_concepts.uniq
end
