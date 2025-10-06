#!/usr/bin/env ruby

require './rag_cag_manager.rb'
require './print.rb'

# Demonstration script for RAG + CAG System
# This script shows how to use the enhanced knowledge retrieval and context-aware generation

puts "Hackerbot RAG + CAG System Demonstration"
puts "=" * 50
puts

# Configuration for demonstration
def demonstrate_basic_configuration
  puts "1. Basic Configuration Demo"
  puts "-" * 30

  rag_config = {
    vector_db: {
      provider: 'chromadb',
      host: 'localhost',
      port: 8000,
      in_memory: true  # Use in-memory ChromaDB for offline demo
    },
    embedding_service: {
      provider: 'mock',  # Use mock provider for offline demo
      model: 'mock-embedding'
    },
    rag_settings: {
      max_results: 3,
      similarity_threshold: 0.5,
      enable_caching: true
    }
  }

  cag_config = {
    knowledge_graph: {
      provider: 'in_memory'
    },
    entity_extractor: {
      provider: 'rule_based'
    },
    cag_settings: {
      max_context_depth: 2,
      max_context_nodes: 15,
      enable_caching: true
    }
  }

  unified_config = {
    enable_rag: true,
    enable_cag: true,
    rag_weight: 0.6,
    cag_weight: 0.4,
    max_context_length: 6000,
    enable_caching: true,
    cache_ttl: 1800,
    auto_initialization: true,
    enable_knowledge_sources: true,
    knowledge_sources_config: [
      {
        type: 'mitre_attack',
        name: 'mitre_attack',
        enabled: true
      }
    ]
  }

  puts "✓ Configuration created successfully"
  puts "  RAG Provider: #{rag_config[:vector_db][:provider]}"
  puts "  CAG Provider: #{cag_config[:knowledge_graph][:provider]}"
  puts "  Max Context Length: #{unified_config[:max_context_length]} characters"
  puts

  return rag_config, cag_config, unified_config
end

def demonstrate_manager_initialization(rag_config, cag_config, unified_config)
  puts "2. Manager Initialization Demo"
  puts "-" * 35

  puts "Initializing RAG + CAG Manager..."
  manager = RAGCAGManager.new(rag_config, cag_config, unified_config)

  if manager.setup
    puts "✓ Manager initialized successfully"

    # Test connections
    if manager.test_connections
      puts "✓ All connections tested successfully"
    else
      puts "⚠ Some connection tests failed"
    end

    puts
    return manager
  else
    puts "✗ Manager initialization failed"
    return nil
  end
end

def demonstrate_knowledge_base_initialization(manager)
  puts "3. Knowledge Base Initialization Demo"
  puts "-" * 40

  puts "Initializing cybersecurity knowledge base..."

  if manager.initialize_knowledge_base
    puts "✓ Knowledge base initialized successfully"

    # Get statistics
    stats = manager.get_retrieval_stats
    puts "  - RAG Collections: #{stats[:rag_collections]&.length || 0}"
    puts "  - RAG Enabled: #{stats[:rag_enabled]}"
    puts "  - CAG Enabled: #{stats[:cag_enabled]}"
    puts "  - Cache Size: #{stats[:cache_size]}"
    puts
  else
    puts "✗ Knowledge base initialization failed"
    puts
  end
end

def demonstrate_entity_extraction(manager)
  puts "4. Entity Extraction Demo"
  puts "-" * 27

  test_messages = [
    "The attack originated from IP 192.168.1.100 and downloaded http://malicious.com/malware.exe",
    "Found suspicious file with hash a1b2c3d4e5f6789012345678901234567890abcd",
    "Attacker connected to port 4444 for C2 communication",
    "Phishing email from attacker@evil.com containing malicious link"
  ]

  test_messages.each do |message|
    puts "Message: \"#{message}\""
    entities = manager.extract_entities(message)

    if entities && !entities.empty?
      puts "Extracted entities:"
      entities.each do |entity|
        puts "  - #{entity[:type].upcase}: #{entity[:value]}"
      end
    else
      puts "  No entities extracted"
    end
    puts
  end
end

def demonstrate_context_retrieval(manager)
  puts "5. Context Retrieval Demo"
  puts "-" * 28

  test_queries = [
    "What is credential dumping?",
    "Explain phishing attacks",
    "How does ransomware work?",
    "What tools are used for network scanning?",
    "Tell me about defense mechanisms"
  ]

  test_queries.each do |query|
    puts "Query: \"#{query}\""
    puts "Retrieving enhanced context..."

    context = manager.get_enhanced_context(query)

    if context && !context.strip.empty?
      puts "✓ Context retrieved (#{context.length} characters)"

      # Show a preview of the context
      preview = context.lines.first(3).join("\n")
      preview = preview.gsub(/=== .*? ===/, "[SECTION]").strip
      puts "Preview:"
      puts "  #{preview}"
      if context.length > 200
        puts "  ... (context truncated for preview)"
      end
    else
      puts "✗ No context retrieved"
    end
    puts
  end
end

def demonstrate_related_entities(manager)
  puts "6. Related Entities Demo"
  puts "-" * 26

  test_entities = [
    "Mimikatz",
    "Emotet",
    "Phishing",
    "Ransomware",
    "EDR"
  ]

  test_entities.each do |entity|
    puts "Finding related entities for: \"#{entity}\""

    related = manager.find_related_entities(entity)

    if related && !related.empty?
      puts "✓ Found #{related.length} related entities:"
      related.each do |rel_entity|
        labels = rel_entity[:labels] || []
        name = rel_entity.dig(:properties, 'name') || rel_entity[:id]
        rel_type = rel_entity[:relationship_type]
        puts "  - #{labels.join(', ')}: #{name} (relation: #{rel_type})"
      end
    else
      puts "  No related entities found"
    end
    puts
  end
end

def demonstrate_custom_knowledge(manager)
  puts "7. Custom Knowledge Demo"
  puts "-" * 27

  puts "Adding custom cybersecurity knowledge..."

  # Custom documents
  custom_documents = [
    {
      id: 'custom_threat_1',
      content: 'Advanced Persistent Threat (APT) groups are sophisticated cyber attackers who target specific organizations over extended periods. They often use zero-day exploits and advanced techniques.',
      metadata: {
        source: 'internal_analysis',
        type: 'threat_intelligence',
        severity: 'high'
      }
    },
    {
      id: 'custom_mitigation_1',
      content: 'Zero Trust Architecture is a security model that requires strict identity verification for every person and device trying to access resources, regardless of whether they are inside or outside the network perimeter.',
      metadata: {
        source: 'security_best_practices',
        type: 'defense_strategy',
        effectiveness: 'very_high'
      }
    }
  ]

  # Custom knowledge triplets
  custom_triplets = [
    {
      subject: 'APT Groups',
      relationship: 'USE_TECHNIQUE',
      object: 'Zero-day Exploits',
      properties: { frequency: 'common', impact: 'high' }
    },
    {
      subject: 'Zero Trust Architecture',
      relationship: 'MITIGATES',
      object: 'Lateral Movement',
      properties: { effectiveness: 'high' }
    },
    {
      subject: 'Advanced Persistent Threat',
      relationship: 'IS_TYPE',
      object: 'Threat Actor',
      properties: { sophistication: 'high', duration: 'long_term' }
    }
  ]

  # Add custom knowledge
  if manager.add_custom_knowledge('custom_cybersecurity', custom_documents, custom_triplets)
    puts "✓ Custom knowledge added successfully"

    # Test retrieval
    puts "\nTesting custom knowledge retrieval..."
    context = manager.get_enhanced_context(
      "What is Zero Trust and how does it relate to APT groups?",
      { custom_collection: 'custom_cybersecurity' }
    )

    if context
      puts "✓ Custom knowledge retrieved successfully"
      if context.include?('Zero Trust') || context.include?('APT') || context.include?('Advanced Persistent Threat')
        puts "✓ Custom knowledge content is present in context"
      else
        puts "⚠ Custom knowledge content not found in context"
      end
    else
      puts "✗ Failed to retrieve custom knowledge"
    end
  else
    puts "✗ Failed to add custom knowledge"
  end
  puts
end

def demonstrate_caching_functionality(manager)
  puts "8. Caching Demo"
  puts "-" * 18

  query = "What is credential dumping?"

  puts "Testing query: \"#{query}\""
  puts "First call (should cache result)..."

  start_time = Time.now
  context1 = manager.get_enhanced_context(query)
  first_call_time = Time.now - start_time

  puts "Second call (should use cache)..."
  start_time = Time.now
  context2 = manager.get_enhanced_context(query)
  second_call_time = Time.now - start_time

  if context1 && context2
    puts "✓ Both calls returned context"
    puts "  First call time: #{(first_call_time * 1000).round(2)}ms"
    puts "  Second call time: #{(second_call_time * 1000).round(2)}ms"

    if context1 == context2
      puts "✓ Cached content matches original"

      if second_call_time < first_call_time
        puts "✓ Cache was faster (#{(first_call_time / second_call_time).round(1)}x speedup)"
      else
        puts "⚠ Cache was not faster (possible caching limitation or small cache overhead)"
      end
    else
      puts "⚠ Cached content differs from original"
    end
  else
    puts "✗ Failed to retrieve context for caching test"
  end
  puts
end

def demonstrate_statistics(manager)
  puts "9. System Statistics Demo"
  puts "-" * 29

  stats = manager.get_retrieval_stats
  puts "System Statistics:"
  puts "  - Initialized: #{stats[:initialized]}"
  puts "  - RAG Enabled: #{stats[:rag_enabled]}"
  puts "  - CAG Enabled: #{stats[:cag_enabled]}"
  puts "  - Cache Size: #{stats[:cache_size]} entries"
  puts

  if stats[:rag_collections]
    puts "RAG Collections:"
    stats[:rag_collections].each do |collection|
      puts "  - #{collection[:name]}: #{collection[:document_count]} documents"
    end
    puts
  end

  if stats[:cag_graph_stats]
    puts "CAG Knowledge Graph:"
    puts "  - Nodes: #{stats[:cag_graph_stats][:node_count]}"
    puts "  - Relationships: #{stats[:cag_graph_stats][:relationship_count]}"
    puts "  - Labels: #{stats[:cag_graph_stats][:labels_count]}"
    puts
  end
end

def demonstrate_cleanup(manager)
  puts "10. Cleanup Demo"
  puts "-" * 18

  puts "Cleaning up RAG + CAG Manager..."

  if manager.cleanup
    puts "✓ Cleanup completed successfully"

    # Verify cleanup
    stats = manager.get_retrieval_stats
    if !stats[:initialized]
      puts "✓ Manager properly cleaned up (not initialized)"
    else
      puts "⚠ Manager still shows as initialized after cleanup"
    end
  else
    puts "✗ Cleanup failed"
  end
  puts
end

def main
  begin
    # Demonstrate each feature
    rag_config, cag_config, unified_config = demonstrate_basic_configuration
    manager = demonstrate_manager_initialization(rag_config, cag_config, unified_config)

    if manager
      demonstrate_knowledge_base_initialization(manager)
      demonstrate_entity_extraction(manager)
      demonstrate_context_retrieval(manager)
      demonstrate_related_entities(manager)
      demonstrate_custom_knowledge(manager)
      demonstrate_caching_functionality(manager)
      demonstrate_statistics(manager)
      demonstrate_cleanup(manager)
    else
      puts "Demonstration aborted due to initialization failure"
      exit 1
    end

    puts "RAG + CAG System Demonstration Completed Successfully!"
    puts "=" * 50

  rescue => e
    puts "Error during demonstration: #{e.message}"
    puts e.backtrace
    exit 1
  end
end

# Run the demonstration
if __FILE__ == $0
  main
end
