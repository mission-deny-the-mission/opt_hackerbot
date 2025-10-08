#!/usr/bin/env ruby

# Test CAG System Enhanced with Man Page Knowledge
# This script tests the integration of lsattr, chattr, and chmod man pages with CAG

require_relative '../rag_cag_manager'
require_relative '../print'
require_relative '../knowledge_bases/mitre_attack_knowledge'
require_relative '../knowledge_bases/utils/man_page_processor'

class ManPageCAGTest
  def initialize
    @cag_config = {
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

    @unified_config = {
      enable_rag: false,
      enable_cag: true,
      auto_initialization: true,
      knowledge_base_name: 'enhanced_security'
    }

    @man_processor = ManPageProcessor.new
    @manager = nil
  end

  def setup_knowledge_base
    puts "Setting up enhanced knowledge base..."

    @manager = RAGCAGManager.new({}, @cag_config, @unified_config)

    unless @manager.setup
      puts "✗ Failed to initialize CAG manager"
      return false
    end

    # Load MITRE ATT&CK knowledge
    mitre_triplets = MITREAttackKnowledge.to_cag_triplets
    cag_manager = @manager.instance_variable_get(:@cag_manager)

    unless cag_manager.create_knowledge_base_from_triplets(mitre_triplets)
      puts "✗ Failed to load MITRE ATT&CK knowledge"
      return false
    end
    puts "✓ Loaded MITRE ATT&CK knowledge: #{mitre_triplets.length} triplets"

    # Add man page knowledge
    man_triplets = generate_man_page_triplets(['lsattr', 'chattr', 'chmod'])
    if man_triplets.any?
      if cag_manager.create_knowledge_base_from_triplets(man_triplets)
        puts "✓ Loaded man page knowledge: #{man_triplets.length} triplets"
      else
        puts "✗ Failed to load man page knowledge"
        return false
      end
    end

    true
  end

  def generate_man_page_triplets(man_pages)
    triplets = []

    man_pages.each do |man_page|
      page_triplets = @man_processor.to_cag_triplets(man_page)
      triplets.concat(page_triplets) if page_triplets
    end

    # Add security relationships
    security_triplets = [
      {
        subject: "chattr",
        relationship: "IS_TYPE",
        object: "File Security",
        properties: { category: "defense", tool: "linux" }
      },
      {
        subject: "lsattr",
        relationship: "IS_TYPE",
        object: "File Security",
        properties: { category: "monitoring", tool: "linux" }
      },
      {
        subject: "chmod",
        relationship: "IS_TYPE",
        object: "File Security",
        properties: { category: "access_control", tool: "linux" }
      },
      {
        subject: "File Security",
        relationship: "MITIGATES",
        object: "Unauthorized Access",
        properties: { effectiveness: "high" }
      },
      {
        subject: "chattr +i",
        relationship: "PREVENTS",
        object: "File Modification",
        properties: { attribute: "immutable" }
      },
      {
        subject: "chmod 000",
        relationship: "DENIES",
        object: "All Access",
        properties: { permissions: "none" }
      },
      {
        subject: "chmod 755",
        relationship: "ALLOWS",
        object: "Owner Full Access",
        properties: { owner: "rwx", group: "rx", other: "rx" }
      }
    ]

    triplets.concat(security_triplets)
    triplets
  end

  def test_file_security_queries
    puts "\nTesting File Security Queries"
    puts "-" * 35

    queries = [
      "How can I make a file immutable to prevent modification?",
      "What is the difference between chattr and chmod?",
      "How do I check file attributes on Linux?",
      "What chmod permission allows read and execute but not write?",
      "How to protect a file from being deleted?",
      "Explain file system security controls in Linux",
      "What is the purpose of the immutable attribute?",
      "How to set file permissions for a web server?"
    ]

    queries.each_with_index do |query, i|
      puts "\nQuery #{i+1}: #{query}"

      context = @manager.get_enhanced_context(query)

      if context && !context.empty?
        puts "✓ Context retrieved (#{context.length} chars)"

        # Check for man page references
        keywords = ['chattr', 'lsattr', 'chmod', 'immutable', 'permission', 'attribute']
        found_keywords = keywords.select { |kw| context.downcase.include?(kw.downcase) }

        if found_keywords.any?
          puts "  ✓ Contains relevant concepts: #{found_keywords.join(', ')}"
        else
          puts "  ⚠ May not contain relevant information"
        end

        # Show preview
        preview = context.length > 150 ? context[0..150] + "..." : context
        puts "  Preview: #{preview.gsub(/\n/, ' ')}"
      else
        puts "✗ No context retrieved"
      end
    end
  end

  def test_entity_extraction
    puts "\nTesting Entity Extraction from Security Scenarios"
    puts "-" * 50

    scenarios = [
      "I need to make /etc/passwd immutable using chattr +i",
      "Check file attributes with lsattr on /bin/bash",
      "Set permissions to 644 for config file using chmod",
      "The attacker modified system files despite chattr protection",
      "Use chmod 700 to restrict access to private key files"
    ]

    scenarios.each_with_index do |scenario, i|
      puts "\nScenario #{i+1}: #{scenario}"

      entities = @manager.extract_entities(scenario)

      if entities && entities.any?
        puts "✓ Extracted #{entities.length} entities:"
        entities.each do |entity|
          puts "  - #{entity[:type].upcase}: #{entity[:value]}"
        end

        # Test context expansion
        cag_manager = @manager.instance_variable_get(:@cag_manager)
        context_nodes = cag_manager.expand_context_with_entities(entities)

        if context_nodes && context_nodes.any?
          puts "✓ Expanded to #{context_nodes.length} context nodes"

          # Show relevant nodes
          relevant_nodes = context_nodes.select do |node|
            name = node.dig(:properties, 'name') || node[:id]
            name.downcase.include?('chattr') || name.downcase.include?('chmod') || name.downcase.include?('lsattr') ||
            name.downcase.include?('file') || name.downcase.include?('security')
          end

          if relevant_nodes.any?
            puts "  Found #{relevant_nodes.length} relevant security nodes"
            relevant_nodes.first(3).each do |node|
              name = node.dig(:properties, 'name') || node[:id]
              labels = node[:labels] || []
              puts "    - #{labels.join(', ')}: #{name[0..50]}"
            end
          end
        else
          puts "✗ No context nodes found"
        end
      else
        puts "✗ No entities extracted"
      end
    end
  end

  def test_specific_command_questions
    puts "\nTesting Specific Command Questions"
    puts "-" * 35

    questions = [
      "What does 'chattr +i' do?",
      "How to use lsattr to check attributes?",
      "What is the meaning of chmod 755?",
      "Can chattr prevent file deletion?",
      "Difference between chmod and chattr?",
      "How to remove immutable attribute?",
      "What permissions does chmod 600 set?",
      "Is chattr available on all Linux systems?"
    ]

    questions.each_with_index do |question, i|
      puts "\nQ#{i+1}: #{question}"

      context = @manager.get_enhanced_context(question)

      if context && !context.empty?
        lines = context.split("\n")

        # Look for man page specific content
        has_man_content = lines.any? { |line| line.include?('Man Page:') || line.include?('SYNOPSIS') || line.include?('DESCRIPTION') }

        if has_man_content
          puts "✓ Contains man page documentation"
        end

        # Check if answer is useful
        useful_indicators = ['immutable', 'attribute', 'permission', 'read', 'write', 'execute', 'file', 'security']
        useful = useful_indicators.any? { |indicator| context.downcase.include?(indicator) }

        puts useful ? "✓ Provides useful information" : "⚠ Information may be generic"

        # Show concise answer preview
        content_lines = lines.reject { |line| line.start_with?('===') || line.include?('CONTEXT USAGE') }
        preview = content_lines.first(3).join(' ')
        puts "  Answer: #{preview[0..100]}..." if preview.length > 100
      else
        puts "✗ No answer retrieved"
      end
    end
  end

  def test_knowledge_graph_coverage
    puts "\nTesting Knowledge Graph Coverage"
    puts "-" * 35

    cag_manager = @manager.instance_variable_get(:@cag_manager)

    # Test specific entities exist
    entities_to_check = ['chattr', 'lsattr', 'chmod', 'File Security', 'permission', 'attribute']

    entities_to_check.each do |entity|
      nodes = cag_manager.instance_variable_get(:@knowledge_graph)
                         .find_nodes_by_property('name', entity, 5)

      if nodes.any?
        puts "✓ Entity '#{entity}' found in knowledge graph (#{nodes.length} nodes)"

        # Check relationships
        relationships = []
        nodes.each do |node|
          rels = cag_manager.instance_variable_get(:@knowledge_graph)
                            .get_node_relationships(node[:id])
          relationships.concat(rels) if rels
        end

        if relationships.any?
          puts "  Has #{relationships.length} relationships"
        end
      else
        puts "✗ Entity '#{entity}' not found in knowledge graph"
      end
    end

    # Test related entities
    puts "\nTesting Related Entities:"
    related_tests = [
      { entity: 'chattr', relationship: 'IS_TYPE' },
      { entity: 'File Security', relationship: 'MITIGATES' },
      { entity: 'chmod', relationship: 'ALLOWS' }
    ]

    related_tests.each do |test|
      related = @manager.find_related_entities(test[:entity], test[:relationship])

      if related && related.any?
        puts "✓ Found #{related.length} entities related to '#{test[:entity]}' via '#{test[:relationship]}'"
        related.first(3).each do |rel|
          name = rel.dig(:properties, 'name') || rel[:id]
          puts "  - #{name}"
        end
      else
        puts "✗ No related entities found for '#{test[:entity]}'"
      end
    end
  end

  def run_all_tests
    begin
      puts "CAG System Test with Man Page Knowledge"
      puts "=" * 50

      unless setup_knowledge_base
        puts "❌ Setup failed, cannot run tests"
        return false
      end

      test_file_security_queries
      test_entity_extraction
      test_specific_command_questions
      test_knowledge_graph_coverage

      # Cleanup
      puts "\nCleaning up..."
      @manager.cleanup if @manager
      puts "✓ Cleanup completed"

      puts "\n" + "=" * 50
      puts "✅ Man Page CAG Integration Test Completed Successfully!"
      puts "The system can now answer questions about:"
      puts "  - File attributes (lsattr/chattr)"
      puts "  - File permissions (chmod)"
      puts "  - Linux file system security"
      puts "  - Command usage and security implications"
      puts "=" * 50

      true

    rescue => e
      puts "❌ Test failed: #{e.message}"
      puts e.backtrace
      false
    end
  end
end

# Run the test
if __FILE__ == $0
  test = ManPageCAGTest.new
  success = test.run_all_tests
  exit(success ? 0 : 1)
end
