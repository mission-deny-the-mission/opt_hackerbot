# Hackerbot - AI-Powered Cybersecurity Training Framework

[![Ruby](https://img.shields.io/badge/Ruby-2.7%2B-red.svg)](https://www.ruby-lang.org/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Documentation](https://img.shields.io/badge/Documentation-Yes-green.svg)](docs/)

Hackerbot is a Ruby-based IRC bot framework designed for cybersecurity training exercises. It combines traditional attack simulation with modern AI capabilities through multiple LLM providers (Ollama, OpenAI, VLLM, SGLang) and advanced knowledge retrieval systems (RAG + CAG).

## 🎯 Overview

Hackerbot provides an interactive platform for cybersecurity education by:
- **Simulating Attack Scenarios**: Progressive training exercises with multiple stages
- **AI-Powered Conversations**: Natural language interactions with LLM-powered bots
- **Knowledge-Enhanced Responses**: Built-in cybersecurity intelligence and documentation
- **Flexible Deployment**: Support for both online and offline operation modes
- **Multi-Provider Support**: Integration with various LLM providers and knowledge sources

## 🚀 Quick Start

### Prerequisites

- **Ruby 2.7+** - Programming language runtime
- **Ollama** (recommended) - Local LLM provider
- **IRC Server** - For bot communication (can be local)

### Installation

1. **Clone and Setup**
   ```bash
   git clone <repository-url>
   cd opt_hackerbot
   ```

2. **Install Ollama** (if using local LLM)
   ```bash
   # Install Ollama
   curl -fsSL https://ollama.ai/install.sh | sh
   
   # Start Ollama service
   ollama serve
   
   # Pull a model (recommended: gemma3:1b for speed)
   ollama pull gemma3:1b
   ```

3. **Install Ruby Dependencies**
   ```bash
   gem install ircinch nokogiri nori
   ```

### Basic Usage

```bash
# Start with default settings
ruby hackerbot.rb

# Start with custom Ollama settings
ruby hackerbot.rb --ollama-host localhost --ollama-port 11434 --ollama-model gemma3:1b

# Enable RAG + CAG knowledge enhancement
ruby hackerbot.rb --enable-rag-cag

# Force offline mode for air-gapped environments
ruby hackerbot.rb --offline
```

## 📚 Documentation

### User Documentation
- **[User Guide](docs/user_guides/user-guide.md)** - Comprehensive user manual
- **[Configuration Guide](docs/user_guides/configuration-guide.md)** - XML configuration reference
- **[Deployment Guide](docs/user_guides/deployment-guide.md)** - Installation and setup instructions

### Developer Documentation
- **[Architecture Overview](docs/development/architecture.md)** - System design and components
- **[Development Guide](docs/development/development-guide.md)** - Contributing and extending
- **[API Reference](docs/development/api-reference.md)** - Technical API documentation
- **[Contributing Guide](docs/development/contributing.md)** - How to contribute

### Knowledge Base
- **[Incident Response Procedures](docs/incident_response_procedures.md)** - Security incident handling
- **[Network Security Best Practices](docs/network_security_best_practices.md)** - Network security guidelines
- **[Threat Intelligence](docs/threat_intelligence/apt_groups.md)** - APT group information

### Quick Reference
- **[Changelog](CHANGELOG.md)** - Version history and changes
- **[Project Guide for AI Agents](AGENTS.md)** - AI agent development guide

## 🏗️ Architecture

### Core Components

```
Hackerbot Framework
├── Core System
│   ├── hackerbot.rb          # Main entry point and CLI
│   ├── bot_manager.rb        # Bot instance management
│   └── print.rb              # Logging and output utilities
├── LLM Integration
│   ├── llm_client.rb         # Base LLM interface
│   ├── llm_client_factory.rb # LLM client factory
│   ├── ollama_client.rb      # Ollama provider
│   ├── openai_client.rb      # OpenAI provider
│   ├── vllm_client.rb        # VLLM provider
│   └── sglang_client.rb      # SGLang provider
├── Knowledge Enhancement
│   ├── rag_cag_manager.rb    # RAG + CAG coordinator
│   ├── rag/                  # Retrieval-Augmented Generation
│   └── cag/                  # Context-Aware Generation
└── Knowledge Bases
    ├── knowledge_bases/      # Cybersecurity intelligence
    └── config/               # XML configurations
```

### Key Features

#### 🤖 AI Integration
- **Multiple LLM Providers**: Ollama, OpenAI, VLLM, SGLang
- **Streaming Responses**: Real-time line-by-line output
- **Per-User Chat History**: Contextual conversations
- **Dynamic Personalities**: Per-attack system prompts for social engineering training

#### 🧠 Knowledge Enhancement
- **RAG System**: Document retrieval and semantic search
- **CAG System**: Entity extraction and knowledge graph analysis
- **Built-in Knowledge**: MITRE ATT&CK framework, security tools, best practices
- **Custom Sources**: Support for man pages, markdown files, and custom documentation

#### 🔒 Security & Deployment
- **Offline Operation**: Air-gapped deployment capability
- **Individual Control**: Enable/disable RAG and CAG independently
- **Resource Efficiency**: Configurable for various deployment environments
- **Secure by Default**: Minimal external dependencies

## ⚙️ Configuration

Bot configurations are defined in XML files in the `config/` directory:

```xml
<hackerbot>
  <name>CybersecurityBot</name>
  <llm_provider>ollama</llm_provider>
  <ollama_model>gemma3:1b</ollama_model>
  <system_prompt>You are a helpful cybersecurity training assistant.</system_prompt>
  <rag_cag_enabled>true</rag_cag_enabled>
  
  <attacks>
    <attack>
      <prompt>Try to extract sensitive information from the target.</prompt>
      <system_prompt>You are a gullible customer service agent who is easily manipulated.</system_prompt>
    </attack>
  </attacks>
</hackerbot>
```

See [Configuration Guide](docs/user_guides/configuration-guide.md) for detailed options and examples.

## 💡 Usage Examples

### Basic Bot Interaction
```bash
# Start the bot
ruby hackerbot.rb --irc-server localhost

# Connect via IRC client
/server localhost 6667
/join #hackerbot
```

### Advanced Configuration
```bash
# Bot with RAG + CAG and custom knowledge
ruby hackerbot.rb \
  --config config/cybersecurity_bot.xml \
  --enable-rag-cag \
  --offline

# Bot with specific LLM provider
ruby hackerbot.rb \
  --llm-provider openai \
  --openai-api-key your-api-key \
  --openai-model gpt-3.5-turbo

# Bot with OpenAI-compatible API (local llama.cpp, Together.ai, etc.)
ruby hackerbot.rb \
  --llm-provider openai \
  --openai-api-key your-api-key \
  --openai-model llama-2-7b-chat \
  --openai-base-url http://localhost:8080/v1

# Bot with Together.ai (OpenAI-compatible)
ruby hackerbot.rb \
  --llm-provider openai \
  --openai-api-key your-together-api-key \
  --openai-model meta-llama/Llama-2-13b-chat-hf \
  --openai-base-url https://api.together.xyz/v1
```

### Social Engineering Training
Configure bots with dynamic personalities for realistic scenarios:
- **Customer Service Agents**: Practice extracting sensitive information
- **IT Administrators**: Learn privilege escalation techniques
- **Security Personnel**: Test defensive awareness and procedures

## 🛠️ Development

### Running Tests
```bash
# Run comprehensive test suite
ruby test/run_tests.rb

# Run quick verification
ruby test/quick_test.rb

# Run specific test file
ruby test/test_llm_client_factory.rb
```

### Contributing
1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Submit a pull request

See [Contributing Guide](docs/development/contributing.md) for detailed guidelines.

## 📊 Performance & Requirements

### System Requirements
- **Memory**: 2GB+ (4GB+ recommended for RAG + CAG)
- **Storage**: 1GB+ (more for knowledge bases)
- **Network**: Optional (offline mode supported)
- **CPU**: Modern multi-core processor recommended

### Performance Optimization
- **RAG-Only Mode**: ~40% memory reduction
- **CAG-Only Mode**: ~35% memory reduction
- **Offline Mode**: Eliminates network latency
- **Streaming**: Improves perceived responsiveness

## 🔒 Security Considerations

### Data Privacy
- **Local Processing**: Ollama provides on-device AI processing
- **Offline Operation**: No external API calls required
- **Configurable Data Sources**: Control knowledge base content
- **Air-Gapped Support**: Full functionality without internet

### API Security
- **Key Management**: Secure storage for external API keys
- **Rate Limiting**: Configurable request limits
- **Fallback Behavior**: Graceful degradation when services unavailable
- **Access Control**: User-specific chat history isolation

## 🤝 Community & Support

### Getting Help
- **Documentation**: Start with the [User Guide](docs/user_guides/user-guide.md)
- **Issues**: Report bugs and request features
- **Discussions**: Join community conversations
- **Examples**: Review configuration files in `config/`

### Contributing
We welcome contributions! Please see our [Contributing Guide](docs/development/contributing.md) for:
- Code standards and patterns
- Testing requirements
- Documentation guidelines
- Pull request process

## 📈 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **MITRE ATT&CK Framework**: For comprehensive cybersecurity knowledge
- **Ruby Community**: For excellent tools and libraries
- **AI/LLM Providers**: Ollama, OpenAI, VLLM, SGLang teams
- **Contributors**: All developers who have helped improve this project

---

**Built with ❤️ for cybersecurity education and training**

For the most up-to-date information, visit our [documentation](docs/) or [changelog](CHANGELOG.md).