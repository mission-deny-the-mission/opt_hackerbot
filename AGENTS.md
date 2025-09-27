# Hackerbot Project Guide for AI Agents

## Project Overview

Hackerbot is a Ruby-based IRC bot framework for cybersecurity training exercises. It combines traditional attack simulation with modern AI capabilities through multiple LLM providers (Ollama, OpenAI, VLLM, SGLang) and advanced knowledge retrieval systems (RAG + CAG).

## Core Architecture

### Main Components
- `hackerbot.rb` - Entry point and CLI handler
- `bot_manager.rb` - Central bot instance controller
- `llm_client.rb` - Base LLM interface with provider-specific implementations
- `rag_cag_manager.rb` - Unified RAG (Retrieval-Augmented Generation) and CAG (Context-Aware Generation) coordinator

### Key Subsystems
1. **LLM Integration**: Multiple provider support with streaming and chat history
2. **RAG System**: Document retrieval and semantic search capabilities
3. **CAG System**: Entity extraction and knowledge graph analysis
4. **Knowledge Bases**: MITRE ATT&CK, man pages, markdown files
5. **Offline Support**: Persistent storage and air-gapped operation

## Development Guidelines

### Project Structure
```
opt_hackerbot/
├── core/               # Main application files
├── llm/                # LLM client implementations  
├── rag/                # Retrieval-Augmented Generation
├── cag/                # Context-Aware Generation
├── knowledge_bases/    # Knowledge sources and processing
├── config/             # XML configuration files
├── docs/               # Documentation
└── test/               # Test suites
```

### Key Files to Know
- `config/example_*.xml` - Configuration examples and templates
- `setup_offline_rag_cag.rb` - Offline mode setup script
- `demo_*.rb` - Interactive demonstration scripts
- `knowledge_bases/mitre_attack_knowledge.rb` - Core threat intelligence

### Configuration System
Bots are configured through XML files in `config/` with these key elements:
- `<llm_provider>` - Ollama, OpenAI, VLLM, or SGLang
- `<rag_cag_enabled>` - Enable/disable knowledge retrieval
- `<attacks>` - Progressive training scenarios
- `<knowledge_sources>` - Custom knowledge base configuration

### Development Tips
1. **LLM Clients**: Implement new providers by extending `llm_client.rb`
2. **Knowledge Sources**: Add new sources by extending `base_knowledge_source.rb`
3. **Configuration**: Use XML files for bot definitions and settings
4. **Testing**: Run tests with `ruby test/test_*.rb`
5. **Offline Mode**: Default operation mode, use `setup_offline_rag_cag.rb` for initial setup

### Best Practices
- Keep LLM client implementations modular and provider-agnostic
- Use the factory pattern for creating LLM instances (`llm_client_factory.rb`)
- Implement proper error handling for external service connections
- Follow the existing naming conventions (snake_case for files and methods)
- Cache expensive operations (embedding generation, knowledge base queries)

### Important Notes
- System defaults to offline operation for security and reliability
- RAG and CAG can be controlled independently per bot
- MITRE ATT&CK framework is included by default in all knowledge bases
- Support for man pages and markdown files as additional knowledge sources

## Getting Started
1. Review configuration examples in `config/`
2. Run `ruby setup_offline_rag_cag.rb` for initial setup
3. Test with `ruby demo_*.rb` scripts
4. Create custom configurations based on examples

This framework provides flexible, offline-capable cybersecurity training with AI-powered conversations and comprehensive knowledge retrieval.