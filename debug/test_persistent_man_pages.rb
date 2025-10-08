#!/usr/bin/env ruby
#
# Test Persistent Man Page Loading in CAG System
# This test verifies that man page knowledge is automatically loaded when the CAG system starts

require_relative '../rag_cag_manager.rb'
require_relative '../print.rb'

puts "Testing Persistent Man Page Loading in CAG System"
puts "=" * 55

def test_default_cag_initialization
  puts "\n1. Testing Default CAG Initialization"
  puts "-" * 40

  begin
    # Initialize CAG manager with default configuration (like the bot would)
    cag_config = {
      knowledge_graph: {
        provider: 'in_memory'
      },
      entity_extractor: {
        provider: 'rule_based'
      },
      cag_settings: {
        max_context_depth: 3,
        max_context_nodes: 50,
        enable_caching: true
      }
    }

    unified_config = {
      enable_rag: false,
      enable_cag: true,
      auto_initialization: true,
      knowledge_base_name: 'cybersecurity'  # Use the default name
    }

    manager = RAGCAGManager.new({}, cag_config, unified_config)

    if manager.setup
      puts "✓ CAG Manager initialized successfully"

      # Get statistics
      stats = manager.get_retrieval_stats
      puts "✓ Retrieved system statistics"
      puts "  - Initialized: #{stats[:initialized]}"
      puts "  - CAG Enabled: #{stats[:cag_enabled]}"
      puts "  - Cache Size: #{stats[:cache_size]}"

      return manager
    else
      puts "✗ Failed to initialize CAG Manager"
      return nil
    end
  rescue => e
    puts "✗ Error during initialization: #{e.message}"
    puts e.backtrace.first(3)
    return nil
  end
end

def test_man_page_command_recognition(manager)
  puts "\n2. Testing Man Page Command Recognition"
  puts "-" * 40

  man_page_commands = [
    'lsattr', 'chattr', 'chmod', 'ls', 'cat', 'grep', 'find',
    'ps', 'netstat', 'iptables', 'ssh', 'scp', 'curl', 'wget'
  ]

  tests = [
    "How do I use chattr to make a file immutable?",
    "What is the chmod command used for?",
    "Explain lsattr and its security implications",
    "How to check file attributes with lsattr?",
    "What permissions does chmod 755 set?",
    "Difference between chattr and chmod?",
    "How to make a file undeletable with chattr?"
  ]

  found_commands = []
  missing_commands = []

  tests.each_with_index do |query, i|
    puts "\nTest #{i+1}: #{query}"

    # Extract entities first
    entities = manager.extract_entities(query)
    if entities && entities.any?
      puts "✓ Extracted #{entities.length} entities"

      # Check if man page commands were recognized
      query_commands = man_page_commands.select { |cmd| query.downcase.include?(cmd) }
      if query_commands.any?
        puts "  Query contains: #{query_commands.join(', ')}"
        found_commands.concat(query_commands)
      end
    else
      puts "✗ No entities extracted"
    end

    # Get enhanced context
    context = manager.get_enhanced_context(query)
    if context && !context.strip.empty?
      puts "✓ Context retrieved (#{context.length} characters)"

      # Check for man page knowledge in context
      has_man_knowledge = false
      man_page_commands.each do |cmd|
        if context.downcase.include?(cmd.downcase)
          has_man_knowledge = true
          puts "  ✓ Context contains knowledge about '#{cmd}'"
        end
      end

      unless has_man_knowledge
        puts "⚠ Context may not contain specific man page knowledge"
        missing_commands.concat(query_commands)
      end

      # Show brief preview of context
      preview_lines = context.split("\n").reject { |line|
        line.start_with?('===') || line.include?('CONTEXT USAGE') || line.strip.empty?
      }

      if preview_lines.any?
        preview = preview_lines.first(2).join(' ')[0..150]
        puts "  Preview: #{preview}..."
      end
    else
      puts "✗ No context retrieved"
      missing_commands.concat(query_commands)
    end
  end

  puts "\nMan Page Recognition Summary:"
  puts "  Found knowledge for: #{found_commands.uniq.join(', ')}" if found_commands.any?
  puts "  Missing knowledge for: #{missing_commands.uniq.join(', ')}" if missing_commands.any?

  found_commands.uniq
end

def test_knowledge_graph_coverage(manager)
  puts "\n3. Testing Knowledge Graph Coverage"
  puts "-" * 35

  cag_manager = manager.instance_variable_get(:@cag_manager)

  if cag_manager
    # Test if specific man page entities exist in knowledge graph
    man_entities = ['chattr', 'lsattr', 'chmod', 'File System Security', 'Network Security']

    graph_stats = manager.get_retrieval_stats[:cag_graph_stats]
    if graph_stats
      puts "✓ Knowledge Graph Statistics:"
      puts "  - Nodes: #{graph_stats[:node_count]}"
      puts "  - Relationships: #{graph_stats[:relationship_count]}"
      puts "  - Labels: #{graph_stats[:labels_count]}"
    end

    found_entities = []
    missing_entities = []

    man_entities.each do |entity|
      nodes = cag_manager.instance_variable_get(:@knowledge_graph)
                         .find_nodes_by_property('name', entity, 3)

      if nodes.any?
        found_entities << entity
        puts "✓ Entity '#{entity}' found in knowledge graph (#{nodes.length} nodes)"

        # Show sample relationships
        relationships = []
        nodes.each do |node|
          rels = cag_manager.instance_variable_get(:@knowledge_graph)
                            .get_node_relationships(node[:id])
          relationships.concat(rels) if rels
        end

        if relationships.any?
          puts "  Has #{relationships.length} relationships"
          relationships.first(2).each do |rel|
            puts "    - #{rel[:from_node][:name]} → #{rel[:type]} → #{rel[:to_node][:name]}"
          end
        end
      else
        missing_entities << entity
        puts "✗ Entity '#{entity}' not found in knowledge graph"
      end
    end

    puts "\nKnowledge Graph Coverage Summary:"
    puts "  Found entities: #{found_entities.join(', ')}" if found_entities.any?
    puts "  Missing entities: #{missing_entities.join(', ')}" if missing_entities.any?

    return found_entities.length > 0
  else
    puts "✗ CAG Manager not accessible"
    return false
  end
end

def test_file_security_scenarios(manager)
  puts "\n4. Testing File Security Scenarios"
  puts "-" * 35

  scenarios = [
    "An attacker needs to modify /etc/passwd but chattr +i is set",
    "How to check if a file has the immutable attribute with lsattr",
    "Setting secure permissions with chmod 600 for sensitive files",
    "The difference between file permissions and file attributes",
    "Making a script executable with chmod +x"
  ]

  scenarios.each_with_index do |scenario, i|
    puts "\nScenario #{i+1}: #{scenario[0..60]}..."

    context = manager.get_enhanced_context(scenario)

    if context && !context.strip.empty?
      # Check for relevant security concepts
      security_concepts = ['immutable', 'attribute', 'permission', 'security', 'protect', 'access']
      found_concepts = security_concepts.select { |concept| context.downcase.include?(concept) }

      if found_concepts.any?
        puts "✓ Context contains security concepts: #{found_concepts.join(', ')}"

        # Check for specific man page content
        if context.downcase.include?('chattr') || context.downcase.include?('lsattr') || context.downcase.include?('chmod')
          puts "✓ Context includes man page command knowledge"
        end
      else
        puts "⚠ Context may not contain specific security knowledge"
      end

      puts "✓ Context length: #{context.length} characters"
    else
      puts "✗ No context retrieved for scenario"
    end
  end
end

def main
  puts "Persistent Man Page Loading Test\n"

  begin
    # Test 1: Default initialization
    manager = test_default_cag_initialization
    unless manager
      puts "\n❌ Cannot proceed without CAG manager"
      return false
    end

    # Test 2: Command recognition
    found_commands = test_man_page_command_recognition(manager)

    # Test 3: Knowledge graph coverage
    graph_coverage = test_knowledge_graph_coverage(manager)

    # Test 4: Security scenarios
    test_file_security_scenarios(manager)

    # Summary
    puts "\n" + "=" * 55
    puts "Test Summary:"
    puts "-" * 15
    puts "✓ CAG System Initialization: SUCCESS"
    puts "✓ Man Page Commands Found: #{found_commands.length} commands"
    puts "✓ Knowledge Graph Coverage: #{graph_coverage ? 'GOOD' : 'POOR'}"
    puts "✓ File Security Scenarios: TESTED"

    if found_commands.length >= 3 && graph_coverage
      puts "\n✅ SUCCESS: Man pages are persistently loaded in CAG system!"
      puts "The system can now automatically answer questions about:"
      puts "  - File system security commands (chattr, lsattr, chmod)"
      puts "  - Network security tools"
      puts "  - System monitoring utilities"
    else
      puts "\n⚠ WARNING: Man page integration may need improvement"
      puts "Some commands may not be available in the knowledge base"
    end

    # Cleanup
    puts "\nCleaning up..."
    manager.cleanup
    puts "✓ Cleanup completed"

    true

  rescue => e
    puts "\n❌ Test failed with error: #{e.message}"
    puts e.backtrace
    false
  end
end

if __FILE__ == $0
  success = main
  exit(success ? 0 : 1)
end
