require 'bot_manager'

# Enable RAG + CAG with default configuration
bot_manager = BotManager.new(
  'localhost',  # IRC server
  'ollama',     # LLM provider
  nil, nil, nil, # Ollama defaults
  nil,          # OpenAI API key
  nil, nil, nil, # Other providers
  true,         # Enable RAG + CAG
  {}            # RAG + CAG configuration
)
```

### Advanced Configuration

```ruby
rag_cag_config = {
  enable_rag: true,
  enable_cag: true,
  rag_weight: 0.6,
  cag_weight: 0.4,
  max_context_length: 4000,
  enable_caching: true,
  cache_ttl: 3600,
  auto_initialization: true,
  
  # RAG-specific configuration
  rag: {
    vector_db: {
      provider: 'chromadb',
      host: 'localhost',
      port: 8000,
      api_key: nil  # For cloud providers
    },
    embedding_service: {
      provider: 'openai',
      api_key: 'your-openai-api-key',
      model: 'text-embedding-ada-002'
    },
    rag_settings: {
      max_results: 5,
      similarity_threshold: 0.7,
      chunk_size: 1000,
      chunk_overlap: 200,
      enable_caching: true
    }
  },
  
  # CAG-specific configuration
  cag: {
    knowledge_graph: {
      provider: 'in_memory',
      host: 'localhost',
      port: 7687,
      username: 'neo4j',
      password: 'password'
    },
    entity_extractor: {
      provider: 'rule_based',
      model: 'en_core_web_sm'  # For spaCy-based extraction
    },
    cag_settings: {
      max_context_depth: 2,
      max_context_nodes: 20,
      entity_types: ['ip_address', 'url', 'hash', 'filename'],
      enable_caching: true
    }
  }
}
```

### Bot XML Configuration

Configure RAG + CAG settings per bot in the XML configuration:

```xml
<hackerbot>
  <name>CybersecurityBot</name>
  <llm_provider>ollama</llm_provider>
  <ollama_model>gemma3:1b</ollama_model>
  
  <!-- RAG + CAG Configuration -->
  <rag_cag_enabled>true</rag_cag_enabled>
  
  <rag_cag_config>
    <rag>
      <max_rag_results>7</max_rag_results>
      <include_rag_context>true</include_rag_context>
      <collection_name>cybersecurity_advanced</collection_name>
    </rag>
    
    <cag>
      <max_cag_depth>3</max_cag_depth>
      <max_cag_nodes>25</max_cag_nodes>
      <include_cag_context>true</include_cag_context>
    </cag>
  </rag_cag_config>
  
  <entity_extraction_enabled>true</entity_extraction_enabled>
  <entity_types>ip_address, url, hash, filename, port, email</entity_types>
  
  <!-- Rest of bot configuration -->
</hackerbot>
```

## Usage Examples

### Basic RAG + CAG Usage

```ruby
# Initialize manager
manager = RAGCAGManager.new(rag_config, cag_config, unified_config)
manager.initialize

# Get enhanced context for a query
query = "What is credential dumping and how do attackers use it?"
context = manager.get_enhanced_context(query)

# Extract entities from a message
entities = manager.extract_entities("Attack from 192.168.1.100 using http://malicious.com/malware.exe")

# Find related entities
related = manager.find_related_entities("Mimikatz")
```

### Integration with Bot Responses

The system automatically enhances bot responses by:

1. **Entity Recognition**: Automatically extracting IP addresses, URLs, hashes, filenames, and other cybersecurity entities
2. **Context Retrieval**: Finding relevant documents and knowledge graph relationships
3. **Prompt Enhancement**: Combining retrieved context with user messages for more informed responses

### Knowledge Base Management

#### Adding Custom Knowledge

```ruby
# Custom documents
documents = [
  {
    id: 'custom_vuln_1',
    content: 'Custom vulnerability description...',
    metadata: { source: 'internal', type: 'vulnerability' }
  }
]

# Custom knowledge triplets
triplets = [
  {
    subject: 'Custom Vulnerability',
    relationship: 'IS_TYPE',
    object: 'Vulnerability'
  }
]

# Add to collection
manager.add_custom_knowledge('custom_collection', documents, triplets)
```

#### Using Built-in Knowledge Bases

The system includes comprehensive cybersecurity knowledge:

- **MITRE ATT&CK Framework**: Attack patterns, techniques, and mitigations
- **Malware Families**: Characteristics, capabilities, and attack patterns
- **Security Tools**: Attack tools, defensive tools, and their methodologies
- **Defense Strategies**: EDR, SIEM, MFA, and security controls

## Testing

### Running Tests

```bash
# Run all tests
ruby test/test_rag_cag_system.rb

# Run specific test methods
ruby -e "require './test/test_rag_cag_system.rb'; TestRAGCAGSystem.new.run_tests"
```

### Test Coverage

The test suite covers:

- Manager initialization and configuration
- Knowledge base loading
- Enhanced context retrieval
- Entity extraction
- Related entity discovery
- Custom knowledge addition
- Caching functionality
- Connection testing
- Error handling

### Performance Considerations

#### Caching
- Enable caching for improved response times
- Configure cache TTL based on knowledge update frequency
- Monitor cache size and memory usage

#### Resource Management
- Set appropriate limits for context length and node counts
- Monitor database connections and query performance
- Use streaming responses for large outputs

## Security Considerations

### API Key Management
- Store API keys securely (environment variables, secrets managers)
- Rotate keys regularly for cloud-based services
- Monitor API usage and costs

### Data Privacy
- Consider data sensitivity when using cloud-based vector databases
- Implement proper access controls for knowledge bases
- Audit knowledge base content and sources

## Troubleshooting

### Common Issues

#### Connection Problems
```ruby
# Test individual components
rag_ok = manager.test_connections
cag_ok = manager.test_connections

# Check detailed status
stats = manager.get_retrieval_stats
```

#### Empty Context
- Verify knowledge base initialization
- Check query similarity thresholds
- Ensure documents contain relevant content

#### Performance Issues
- Reduce context size limits
- Enable caching
- Consider using local embeddings for faster processing

### Debug Logging
Enable debug logging to troubleshoot issues:

```ruby
Print.enable_debug = true
manager.initialize
```

## Advanced Features

### Custom Entity Extractors
Implement custom entity extraction for specialized use cases:

```ruby
class CustomEntityExtractor < EmbeddingServiceInterface
  def extract_entities(text, entity_types)
    # Custom entity extraction logic
  end
end
```

### Knowledge Graph Enrichment
Enhance knowledge graphs with external data sources:

```ruby
# Enrich with external threat intelligence
triplets = fetch_external_threat_intelligence()
manager.add_custom_knowledge('threat_intelligence', [], triplets)
```

### Multi-Collection Support
Use multiple knowledge collections for different domains:

```ruby
# Get context from specific collection
context = manager.get_enhanced_context(
  query, 
  { custom_collection: 'malware_analysis' }
)
```

## Future Enhancements

### Planned Features
- Support for additional vector database providers
- Advanced NLP-based entity extraction
- Real-time knowledge base updates
- Multi-modal knowledge (images, videos)
- Collaborative knowledge base editing

### Integration Opportunities
- Threat intelligence platforms
- SIEM systems
- Vulnerability scanners
- Security orchestration platforms

## Contributing

To contribute to the RAG + CAG system:

1. Add tests for new features
2. Update documentation
3. Follow existing code patterns
4. Ensure backward compatibility
5. Test with multiple providers

## License

This RAG + CAG system is part of the Hackerbot framework and follows the same licensing terms.