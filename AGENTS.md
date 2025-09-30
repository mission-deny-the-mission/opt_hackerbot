# Hackerbot Project Guide for AI Agents

## Project Overview

Hackerbot is a Ruby-based IRC bot framework for cybersecurity training exercises. It combines traditional attack simulation with modern AI capabilities through multiple LLM providers (Ollama, OpenAI, VLLM, SGLang) and advanced knowledge retrieval systems (RAG + CAG).

**Development Environment**: This project uses a comprehensive Nix development environment that provides reproducible builds, automatic dependency management, and integrated IRC server functionality.

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
- `flake.nix` - Nix flake configuration for reproducible development environment
- `Makefile` - Development commands and shortcuts
- `simple_irc_server.py` - Custom Python IRC server implementation
- `Gemfile` - Ruby dependencies specification

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
6. **Nix Environment**: Always work within the Nix development environment for consistent dependencies
7. **IRC Server**: Use the built-in Python IRC server on port 6667 for testing

### Best Practices
- Keep LLM client implementations modular and provider-agnostic
- Use the factory pattern for creating LLM instances (`llm_client_factory.rb`)
- Implement proper error handling for external service connections
- Follow the existing naming conventions (snake_case for files and methods)
- Cache expensive operations (embedding generation, knowledge base queries)
- DO NOT commit or push using git WIHTOUT being asked to

### Important Notes
- System defaults to offline operation for security and reliability
- RAG and CAG can be controlled independently per bot
- MITRE ATT&CK framework is included by default in all knowledge bases
- Support for man pages and markdown files as additional knowledge sources

This framework provides flexible, offline-capable cybersecurity training with AI-powered conversations and comprehensive knowledge retrieval.

## Nix Development Environment

### Environment Setup
The project uses Nix flakes for reproducible development environments. The environment includes:
- **Ruby 3.1** with all required gems
- **Python IRC server** (custom implementation)
- **WeeChat** IRC client for testing
- **Development tools** (git, vim, curl, etc.)

### Quick Start
```bash
# Enter development environment
cd opt_hackerbot
nix develop

# Or use direnv for automatic activation
direnv allow

# Start IRC server
make start-irc

# Start Hackerbot
make bot
```

### Available Commands
```bash
# Environment management
make dev          # Enter Nix environment
make setup        # Initial project setup
make verify       # Full environment verification

# IRC server
make start-irc    # Start IRC server (port 6667)
make stop-irc     # Stop IRC server
make restart-irc  # Restart IRC server
make status       # Check server status

# Bot operations
make bot          # Start bot with defaults
make bot-ollama   # Start with Ollama LLM
make bot-rag-cag  # Start with RAG + CAG enabled

# Development
make test         # Run test suite
make install-gems # Install Ruby gems
make clean        # Clean temporary files
```

### Project Structure (Updated)
```
opt_hackerbot/
├── rag/                    # Retrieval-Augmented Generation
├── cag/                    # Context-Aware Generation
├── knowledge_bases/        # Knowledge sources and processing
├── config/                 # XML configuration files
├── docs/                   # Documentation
├── test/                   # Test suites
├── flake.nix              # Nix flake configuration
├── Makefile               # Development commands
├── Gemfile               # Ruby dependencies
├── simple_irc_server.py   # Custom IRC server
├── .gems/                 # Local gem installation directory
└── QUICKSTART.md          # User guide
```

### Development Workflow
1. **Environment Setup**: `nix develop` or `direnv allow`
2. **IRC Server**: `make start-irc` (runs on localhost:6667)
3. **IRC Client**: `make connect-irc` or use any IRC client
4. **Bot Development**: Edit code and test with `make bot`
5. **Testing**: `make test` to run test suite
6. **Gem Management**: Gems installed in local `.gems/` directory

### IRC Server Details
- **Implementation**: Custom Python IRC server (`simple_irc_server.py`)
- **Port**: 6667 (standard IRC port)
- **Channel**: #hackerbot (auto-created)
- **Protocol Support**: Full IRC protocol implementation
- **Features**: NICK, USER, JOIN, PART, PRIVMSG, PING/PONG, WHOIS, LIST, NAMES
- **Configuration**: Environment variables `IRC_HOST` and `IRC_PORT`

### Ruby Gem Management
- **Location**: Local `.gems/` directory (isolated from system gems)
- **Installation**: Automatic via Nix environment or `make install-gems`
- **Key Gems**: ircinch, nokogiri, nori, json, httparty
- **No Bundler Conflicts**: Uses manual gem installation to avoid version issues

### Environment Variables
```bash
RUBYOPT="-KU -E utf-8:utf-8"    # Ruby UTF-8 encoding
IRCD_PORT="6667"                 # IRC server port
IRCD_HOST="localhost"             # IRC server host
GEM_HOME="./.gems"               # Local gem directory
GEM_PATH="./.gems"               # Gem path
IRC_HOST="127.0.0.1"             # IRC server bind address
IRC_PORT="6667"                  # IRC server port
```

### Troubleshooting Common Issues

**IRC Server Problems:**
```bash
# Check if server is running
make status

# Check process
ps aux | grep simple_irc_server

# Restart server
make restart-irc

# Check port usage
sudo lsof -i :6667
```

**Gem Installation Issues:**
```bash
# Clean and reinstall
make clean
make install-gems

# Check environment
make env

# Verify Nix environment
nix flake check
```

**Environment Issues:**
```bash
# Reload environment
direnv allow

# Check Nix
nix --version

# Enter clean environment
nix develop --clean
```

### Key Files for AI Agents

**Configuration Files:**
- `flake.nix` - Complete Nix environment definition
- `Makefile` - All development commands and workflows
- `simple_irc_server.py` - IRC server implementation

**Development Files:**
- `Gemfile` - Ruby dependencies specification
- `.gems/` - Local gem installation directory
- `ircd.conf` - IRC server configuration (auto-generated)

**Documentation:**
- `QUICKSTART.md` - Comprehensive user guide
- `DEVELOPMENT.md` - Detailed development documentation
- `README.md` - Project overview and setup

### Integration Testing
The environment provides integrated testing capabilities:
1. Start IRC server with `make start-irc`
2. Connect with IRC client using `make connect-irc`
3. Start bot with `make bot` or specific variants
4. Test interactions in real-time
5. Use `make test` for automated test suite

### Performance Considerations
- **Local Gems**: Faster loading, no network dependencies
- **Python IRC Server**: Lightweight, minimal resource usage
- **Nix Caching**: Subsequent environment loads are faster
- **Isolated Environment**: No conflicts with system packages

This Nix development environment provides a complete, reproducible setup for Hackerbot development with integrated IRC server capabilities and comprehensive tooling for AI agent development and testing.
