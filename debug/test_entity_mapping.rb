#!/usr/bin/env ruby

# Test Entity Mapping Functionality
# This script tests the enhanced entity mapping in the CAG system

require_relative '../rag_cag_manager.rb'
require_relative '../print.rb'
require_relative '../knowledge_bases/mitre_attack_knowledge.rb'

puts "Testing Entity Mapping Functionality"
puts "=" * 40

def test_entity_mapping_directly
  puts "\n1. Testing Entity Mapping Directly"
  puts "-" * 35

  # Create a CAG manager to test the mapping method
  cag_config = {
    knowledge_graph: { provider: 'in_memory' },
    entity_extractor: { provider: 'rule_based' },
    cag_settings: { max_context_depth: 3, max_context_nodes: 25 }
  }

  unified_config = {
    enable_rag: false,
    enable_cag: true,
    auto_initialization: true
  }

  manager = RAGCAGManager.new({}, cag_config, unified_config)

  if manager.setup
    puts "✓ CAG Manager initialized"

    # Load knowledge base
    cag_triplets = MITREAttackKnowledge.to_cag_triplets
    cag_manager = manager.instance_variable_get(:@cag_manager)

    if cag_manager.create_knowledge_base_from_triplets(cag_triplets)
      puts "✓ Knowledge base loaded with #{cag_triplets.length} triplets"
    else
      puts "✗ Failed to load knowledge base"
      return
    end

    # Test entity mapping
    test_entities = [
      { type: 'ip_address', value: '192.168.1.100' },
      { type: 'url', value: 'http://malicious.com/malware.exe' },
      { type: 'filename', value: 'suspicious.dll' },
      { type: 'hash', value: '1a2b3c4d5e6f7890abcdef1234567890abcdef1234' },
      { type: 'port', value: '4444' },
      { type: 'email', value: 'attacker@evil.com' }
    ]

    test_entities.each do |entity|
      puts "\nTesting entity: #{entity[:type]} = #{entity[:value]}"

      # Test direct node lookup
      direct_nodes = cag_manager.instance_variable_get(:@knowledge_graph)
                        .find_nodes_by_property('name', entity[:value], 5)
      puts "  Direct matches: #{direct_nodes.length}"

      # Test entity mapping
      if cag_manager.respond_to?(:map_entity_to_concepts)
        concepts = cag_manager.map_entity_to_concepts(entity)
        puts "  Mapped concepts: #{concepts.join(', ')}"

        # Test if mapped concepts exist in graph
        concepts.each do |concept|
          concept_nodes = cag_manager.instance_variable_get(:@knowledge_graph)
                              .find_nodes_by_property('name', concept, 3)
          puts "    '#{concept}' matches: #{concept_nodes.length}"
        end
      else
        puts "  ✗ map_entity_to_concepts method not found"
      end
    end

    manager.cleanup
  else
    puts "✗ Failed to initialize CAG Manager"
  end
end

def test_context_expansion_with_mapping
  puts "\n2. Testing Context Expansion with Entity Mapping"
  puts "-" * 50

  # Create manager with knowledge
  cag_config = {
    knowledge_graph: { provider: 'in_memory' },
    entity_extractor: { provider: 'rule_based' },
    cag_settings: { max_context_depth: 3, max_context_nodes: 25 }
  }

  unified_config = {
    enable_rag: false,
    enable_cag: true,
    auto_initialization: true
  }

  manager = RAGCAGManager.new({}, cag_config, unified_config)

  if manager.setup
    # Load knowledge base
    cag_triplets = MITREAttackKnowledge.to_cag_triplets
    cag_manager = manager.instance_variable_get(:@cag_manager)
    cag_manager.create_knowledge_base_from_triplets(cag_triplets)

    # Test the problematic scenario
    scenario = "The attack came from 192.168.1.100 using http://malicious.com/malware.exe"
    puts "Scenario: #{scenario}"

    # Extract entities
    entities = manager.extract_entities(scenario)
    puts "Extracted entities: #{entities.length}"
    entities.each { |e| puts "  - #{e[:type]}: #{e[:value]}" }

    # Test context expansion with CAG only
    context_nodes = cag_manager.expand_context_with_entities(entities)
    puts "Context nodes found: #{context_nodes.length}"

    if context_nodes.length > 0
      puts "✓ Context expansion successful!"
      context_nodes.first(3).each do |node|
        name = node.dig(:properties, 'name') || node[:id]
        labels = node[:labels] || []
        puts "  - #{labels.join(', ')}: #{name}"
      end
    else
      puts "✗ No context nodes found"
    end

    # Test enhanced context retrieval
    context = manager.get_enhanced_context(scenario)
    if context && !context.strip.empty?
      puts "\n✓ Enhanced context retrieved (#{context.length} characters)"

      # Show preview
      preview = context.length > 300 ? context[0..300] + "..." : context
      puts "Preview:"
      puts preview.gsub(/\n/, ' ')
    else
      puts "\n✗ No enhanced context retrieved"
    end

    manager.cleanup
  else
    puts "✗ Failed to initialize manager"
  end
end

def test_various_scenarios
  puts "\n3. Testing Various Attack Scenarios"
  puts "-" * 38

  scenarios = [
    "The attack came from 192.168.1.100 using http://malicious.com/malware.exe",
    "Found file suspicious.dll with hash 1a2b3c4d5e6f7890abcdef1234567890abcdef1234",
    "Phishing email from attacker@evil.com containing malicious link",
    "Connected to C2 server on port 4444",
    "Attacker used Mimikatz to dump credentials"
  ]

  # Create manager
  cag_config = {
    knowledge_graph: { provider: 'in_memory' },
    entity_extractor: { provider: 'rule_based' },
    cag_settings: { max_context_depth: 3, max_context_nodes: 25 }
  }

  unified_config = {
    enable_rag: false,
    enable_cag: true,
    auto_initialization: true
  }

  manager = RAGCAGManager.new({}, cag_config, unified_config)

  if manager.setup
    # Load knowledge
    cag_triplets = MITREAttackKnowledge.to_cag_triplets
    cag_manager = manager.instance_variable_get(:@cag_manager)
    cag_manager.create_knowledge_base_from_triplets(cag_triplets)

    scenarios.each_with_index do |scenario, i|
      puts "\nScenario #{i+1}: #{scenario[0..60]}..."

      context = manager.get_enhanced_context(scenario)

      if context && !context.strip.empty?
        puts "  ✓ Context retrieved (#{context.length} chars)"

        # Check for relevant keywords
        relevant_keywords = ['attack', 'malware', 'tool', 'technique', 'mitigation', 'credential']
        found_keywords = relevant_keywords.select { |kw| context.downcase.include?(kw) }

        if !found_keywords.empty?
          puts "  ✓ Contains relevant concepts: #{found_keywords.join(', ')}"
        else
          puts "  ⚠ May not contain relevant information"
        end
      else
        puts "  ✗ No context retrieved"
      end
    end

    manager.cleanup
  else
    puts "✗ Failed to initialize manager"
  end
end

def main
  begin
    test_entity_mapping_directly
    test_context_expansion_with_mapping
    test_various_scenarios

    puts "\n" + "=" * 40
    puts "✅ Entity Mapping Testing Completed!"
    puts "=" * 40

  rescue => e
    puts "\n❌ Test failed: #{e.message}"
    puts e.backtrace
    exit 1
  end
end

# Run the test
if __FILE__ == $0
  main
end
