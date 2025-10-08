#!/usr/bin/env ruby

# Script to add man pages to CAG knowledge database
# This script adds lsattr, chattr, and chmod man pages to the knowledge base

require_relative '../rag_cag_manager'
require_relative '../print'
require_relative '../knowledge_bases/utils/man_page_processor'
require_relative '../knowledge_bases/mitre_attack_knowledge'

class ManPageEnhancer
  def initialize
    @man_processor = ManPageProcessor.new
    @rag_documents = []
    @cag_triplets = []
  end

  def add_man_pages(man_page_names)
    puts "Adding man pages: #{man_page_names.join(', ')}"

    man_page_names.each do |man_name|
      puts "\nProcessing man page: #{man_name}"

      # Check if man page exists
      if @man_processor.man_page_exists?(man_name)
        puts "✓ Man page '#{man_name}' is available on the system"

        # Generate RAG document
        rag_doc = @man_processor.to_rag_document(man_name)
        if rag_doc
          @rag_documents << rag_doc
          puts "  ✓ Generated RAG document: #{rag_doc[:id]}"
        else
          puts "  ✗ Failed to generate RAG document for #{man_name}"
        end

        # Generate CAG triplets
        triplets = @man_processor.to_cag_triplets(man_name)
        if triplets && triplets.any?
          @cag_triplets.concat(triplets)
          puts "  ✓ Generated #{triplets.length} CAG triplets"
        else
          puts "  ✗ Failed to generate CAG triplets for #{man_name}"
        end
      else
        puts "✗ Man page '#{man_name}' not found on the system"
      end
    end
  end

  def integrate_with_mitre_knowledge
    puts "\nIntegrating man pages with MITRE ATT&CK knowledge..."

    # Add relationships between file system commands and security concepts
    file_security_triplets = [
      {
        subject: "chattr",
        relationship: "IS_TYPE",
        object: "File System Security",
        properties: {
          category: "defense",
          purpose: "file attribute management",
          security_level: "medium"
        }
      },
      {
        subject: "lsattr",
        relationship: "IS_TYPE",
        object: "File System Security",
        properties: {
          category: "monitoring",
          purpose: "attribute inspection",
          security_level: "low"
        }
      },
      {
        subject: "chmod",
        relationship: "IS_TYPE",
        object: "File System Security",
        properties: {
          category: "defense",
          purpose: "permission management",
          security_level: "high"
        }
      },
      {
        subject: "File System Security",
        relationship: "MITIGATES",
        object: "Lateral Movement",
        properties: {
          effectiveness: "high",
          technique: "T1574"
        }
      },
      {
        subject: "File System Security",
        relationship: "MITIGATES",
        object: "Persistence",
        properties: {
          effectiveness: "medium",
          technique: "T1543"
        }
      },
      {
        subject: "chattr",
        relationship: "PREVENTS",
        object: "Unauthorized Modification",
        properties: {
          effectiveness: "high",
          attribute: "immutable"
        }
      },
      {
        subject: "chmod",
        relationship: "CONTROLS",
        object: "File Access",
        properties: {
          mechanism: "permissions",
          scope: "user_group_other"
        }
      }
    ]

    @cag_triplets.concat(file_security_triplets)
    puts "✓ Added #{file_security_triplets.length} security relationship triplets"
  end

  def save_to_knowledge_base(manager)
    puts "\nSaving man page knowledge to CAG system..."

    if @cag_triplets.any?
      cag_manager = manager.instance_variable_get(:@cag_manager)
      if cag_manager && cag_manager.respond_to?(:create_knowledge_base_from_triplets)
        if cag_manager.create_knowledge_base_from_triplets(@cag_triplets)
          puts "✓ Successfully added #{@cag_triplets.length} CAG triplets to knowledge base"
        else
          puts "✗ Failed to add CAG triplets to knowledge base"
        end
      else
        puts "✗ CAG manager not available"
      end
    else
      puts "⚠ No CAG triplets to add"
    end

    if @rag_documents.any?
      rag_manager = manager.instance_variable_get(:@rag_manager)
      if rag_manager && rag_manager.respond_to?(:add_knowledge_base)
        collection_name = "man_pages_#{Time.now.to_i}"
        if rag_manager.add_knowledge_base(collection_name, @rag_documents)
          puts "✓ Successfully added #{@rag_documents.length} RAG documents to '#{collection_name}'"
        else
          puts "✗ Failed to add RAG documents"
        end
      else
        puts "⚠ RAG manager not available or RAG disabled"
      end
    else
      puts "⚠ No RAG documents to add"
    end
  end

  def print_statistics
    puts "\nMan Page Enhancement Statistics:"
    puts "=" * 40
    puts "RAG Documents: #{@rag_documents.length}"
    puts "CAG Triplets: #{@cag_triplets.length}"

    if @cag_triplets.any?
      puts "\nTop CAG Relationships:"
      @cag_triplets.first(10).each do |triplet|
        puts "  #{triplet[:subject]} --#{triplet[:relationship]}--> #{triplet[:object]}"
      end
    end
  end
end

def main
  begin
    puts "Man Page Enhancement for CAG System"
    puts "=" * 50

    # Target man pages
    man_pages = ['lsattr', 'chattr', 'chmod']

    # Initialize the enhancer
    enhancer = ManPageEnhancer.new

    # Process man pages
    enhancer.add_man_pages(man_pages)

    # Integrate with MITRE knowledge
    enhancer.integrate_with_mitre_knowledge

    # Initialize the manager
    puts "\nInitializing CAG Manager..."

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
      enable_rag: false,  # Focus on CAG for this demo
      enable_cag: true,
      auto_initialization: true,
      knowledge_base_name: 'enhanced_cybersecurity'
    }

    manager = RAGCAGManager.new({}, cag_config, unified_config)

    if manager.setup
      puts "✓ CAG Manager initialized successfully"

      # Load MITRE knowledge first (as baseline)
      puts "Loading MITRE ATT&CK knowledge..."
      cag_triplets = MITREAttackKnowledge.to_cag_triplets
      cag_manager = manager.instance_variable_get(:@cag_manager)
      if cag_manager.create_knowledge_base_from_triplets(cag_triplets)
        puts "✓ MITRE ATT&CK knowledge loaded: #{cag_triplets.length} triplets"
      else
        puts "✗ Failed to load MITRE ATT&CK knowledge"
      end

      # Add man page knowledge
      enhancer.save_to_knowledge_base(manager)

      # Test the enhanced system
      puts "\nTesting Enhanced CAG System"
      puts "-" * 30

      test_queries = [
        "What is the chattr command used for?",
        "How do I make a file immutable with chattr?",
        "What are file attributes in Linux?",
        "How does chmod relate to file security?",
        "Explain file system security controls"
      ]

      test_queries.each do |query|
        puts "\nQuery: #{query}"
        context = manager.get_enhanced_context(query)

        if context && !context.empty?
          puts "✓ Context retrieved (#{context.length} characters)"

          # Check for man page references
          if context.downcase.include?('chattr') || context.downcase.include?('lsattr') || context.downcase.include?('chmod')
            puts "✓ Context contains man page information"
          end

          # Show preview
          preview = context.length > 200 ? context[0..200] + "..." : context
          puts "Preview: #{preview.gsub(/\n/, ' ')}"
        else
          puts "✗ No context retrieved"
        end
      end

      # Print statistics
      enhancer.print_statistics

      # Cleanup
      puts "\nCleaning up..."
      manager.cleanup
      puts "✓ Cleanup completed"

      puts "\n" + "=" * 50
      puts "✅ Man Page Enhancement Completed Successfully!"
      puts "The CAG system now includes knowledge about:"
      puts "  - lsattr: List file attributes"
      puts "  - chattr: Change file attributes"
      puts "  - chmod: Change file permissions"
      puts "=" * 50

    else
      puts "✗ Failed to initialize CAG Manager"
      exit 1
    end

  rescue => e
    puts "❌ Error: #{e.message}"
    puts e.backtrace
    exit 1
  end
end

if __FILE__ == $0
  main
end
