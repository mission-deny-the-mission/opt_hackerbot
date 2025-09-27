# Hackerbot Agents System

Hackerbot is a Ruby-based IRC bot framework designed for cybersecurity training exercises. It combines traditional attack simulation with modern AI capabilities through integration with multiple LLM providers and advanced knowledge retrieval systems. The system now defaults to offline operation and supports independent control of RAG and CAG components.

## Overview

The system consists of intelligent IRC bots that can guide users through progressive cybersecurity challenges while maintaining contextual conversations using LLMs. Each bot can adapt its personality and behavior based on the current training scenario. Hackerbot supports multiple LLM backends including Ollama, OpenAI, VLLM, and SGLang, and features advanced RAG (Retrieval-Augmented Generation) and CAG (Context-Aware Generation) capabilities for intelligent, context-aware cybersecurity training.

## Core Components

### Main Application
- `hackerbot.rb` - Entry point that handles command-line arguments and initializes the bot manager
- `bot_manager.rb` - Central controller that manages multiple bot instances and their configurations
- `llm_client.rb` - Base class for all LLM clients
- `ollama_client.rb` - Interface for communicating with Ollama LLM services
- `openai_client.rb` - Interface for communicating with OpenAI API
- `vllm_client.rb` - Interface for communicating with VLLM servers
- `sglang_client.rb` - Interface for communicating with SGLang servers
- `llm_client_factory.rb` - Factory for creating appropriate LLM client instances

### RAG + CAG System
- `rag_cag_manager.rb` - Unified manager coordinating RAG and CAG operations
- `rag/rag_manager.rb` - RAG operations coordinator for document retrieval
- `cag/cag_manager.rb` - CAG operations coordinator for knowledge graph traversal
- `rag/vector_db_interface.rb` - Base interface for vector database implementations
- `rag/embedding_service_interface.rb` - Base interface for embedding service implementations
- `cag/knowledge_graph_interface.rb` - Base interface for knowledge graph implementations
- `knowledge_bases/mitre_attack_knowledge.rb` - Comprehensive MITRE ATT&CK framework knowledge
- `knowledge_bases/knowledge_source_manager.rb` - Manager for multiple knowledge sources
- `knowledge_bases/base_knowledge_source.rb` - Base interface for knowledge sources
- `knowledge_bases/sources/man_pages/man_page_knowledge.rb` - Man page knowledge source
- `knowledge_bases/sources/markdown_files/markdown_knowledge.rb` - Markdown file knowledge source
- `knowledge_bases/utils/man_page_processor.rb` - Man page extraction and processing
- `knowledge_bases/utils/markdown_processor.rb` - Markdown file parsing and analysis

### Offline Operation Support
- `rag_cag_offline_config.rb` - Offline configuration and connectivity detection (offline is now the default)
- `rag/chromadb_offline_client.rb` - Persistent vector database for offline operation
- `rag/ollama_embedding_offline_client.rb` - Local embedding service with caching
- `cag/in_memory_graph_offline_client.rb` - Persistent knowledge graph for offline operation
- `setup_offline_rag_cag.rb` - Comprehensive offline setup and configuration script

### Configuration System
Bots are configured through XML files located in the `config/` directory:
- `<name>` - Unique identifier for the bot
- `<llm_provider>` - LLM provider to use (ollama, openai, vllm, sglang)
- `<get_shell>` - Shell access configuration
- `<messages>` - Static response templates
- `<attacks>` - Progressive challenge scenarios
- `<rag_cag_enabled>` - Enable/disable RAG + CAG capabilities
- `<rag_enabled>` - Enable only RAG system (optional, defaults to true if rag_cag_enabled)
- `<cag_enabled>` - Enable only CAG system (optional, defaults to true if rag_cag_enabled)
- `<rag_cag_config>` - RAG + CAG specific configuration
- `<knowledge_sources>` - Enhanced knowledge sources configuration (man pages, markdown files)

### LLM Integration
- Support for multiple LLM providers: Ollama, OpenAI, VLLM, SGLang
- Per-user chat history management for contextual conversations
- Streaming responses for real-time interaction
- Per-attack system prompts for dynamic personality changes
- Enhanced context through RAG + CAG knowledge retrieval

## Key Features

### Multi-Bot Management
- Single manager controls multiple concurrent bot instances
- Each bot operates in its own IRC channels
- Independent configuration per bot
- Shared or per-bot knowledge bases

### Individual System Control
- **RAG-Only Mode**: Enable only document retrieval and semantic search capabilities
- **CAG-Only Mode**: Enable only entity extraction and knowledge graph analysis
- **Independent Configuration**: Per-bot control over which systems are active
- **Resource Optimization**: Reduce memory and processing requirements by using only needed components

### Progressive Attack System
- Structured learning paths through numbered attack scenarios
- Navigation commands (`next`, `previous`, `goto`)
- Conditional progression based on user responses
- Automated verification of correct answers
- Context-aware attack explanations

### AI-Powered Conversations
- Natural language understanding through multiple LLM providers
- Context retention through per-user chat history
- Dynamic personality adaptation per training stage
- Real-time streaming responses for better interactivity
- Enhanced responses with RAG + CAG knowledge retrieval

### Interactive Learning
- Quiz-based knowledge verification
- Hands-on shell command execution
- Immediate feedback mechanisms
- Comprehensive help system
- Intelligent explanations and contextual guidance

### RAG + CAG Capabilities
- **Retrieval-Augmented Generation**: Access to comprehensive cybersecurity knowledge bases
- **Context-Aware Generation**: Intelligent relationship mapping and entity discovery
- **Knowledge Graph Integration**: MITRE ATT&CK framework, CVE databases, and security tools
- **Entity Recognition**: Automatic extraction of IPs, URLs, hashes, filenames, and other cybersecurity entities
- **Semantic Search**: Find relevant information across multiple knowledge domains
- **Offline Operation**: Full functionality without internet connectivity after setup

### Enhanced Knowledge Sources
- **Man Pages Integration**: Direct access to Unix/Linux command documentation with section-aware processing
- **Markdown Files Support**: Include custom documentation by file path with metadata extraction and tagging
- **Flexible Configuration**: Define multiple knowledge sources in XML with collection organization and priority ordering
- **Intelligent Processing**: Automatic content extraction, relationship mapping, and knowledge graph integration
- **Multi-Source Queries**: Retrieve relevant information across MITRE ATT&CK, man pages, and markdown documentation simultaneously
- **Caching System**: Performance-optimized caching for man pages and markdown files with intelligent invalidation

### Offline Operation
- **Default Offline Mode**: System now defaults to offline operation for enhanced security and reliability
- **Air-Gapped Support**: Complete offline functionality with pre-downloaded knowledge bases
- **Persistent Storage**: Local embeddings and knowledge graph storage
- **Auto-Detection**: Automatic connectivity detection and fallback to offline mode
- **Knowledge Management**: Import, export, and management of offline knowledge bases
- **Performance Optimization**: Efficient local storage and retrieval with compression

## Agent Capabilities

### Social Engineering Training
Agents can role-play various personas:
- Gullible customer service representatives
- Naive IT administrators
- Trusting employees with sensitive access
- Context-aware responses based on retrieved social engineering patterns

### AI Security Exercises
Agents simulate vulnerable AI systems for:
- Prompt injection attack training
- LLM security awareness
- Responsible AI interaction practices
- AI vulnerability assessment with knowledge base guidance

### Traditional Cybersecurity Drills
Agents guide users through:
- Network reconnaissance with contextual threat intelligence
- Exploitation techniques with MITRE ATT&CK framework references
- Post-exploitation activities with defense strategy recommendations
- Incident response procedures with knowledge-based guidance

### Knowledge-Enhanced Training
Agents provide intelligent explanations using:
- **Attack Pattern Analysis**: Detailed explanations from MITRE ATT&CK framework
- **Vulnerability Context**: Related CVE information and mitigation strategies
- **Tool Recommendations**: Context-aware security tool suggestions
- **Defense Strategies**: Knowledge-based defense recommendations
- **Entity Relationships**: Understanding connections between different cyber threats

## Supported LLM Providers

### Ollama
Local LLM inference engine with support for many models.
- **Offline Support**: Full offline operation with local model downloads
- **Embedding Models**: Support for nomic-embed-text and other embedding models
- **Performance Optimized**: Efficient local inference with caching

### OpenAI
Cloud-based API access to GPT models with API key authentication.
- **Embedding Integration**: text-embedding-ada-002 for semantic search
- **Streaming Support**: Real-time response streaming
- **Model Flexibility**: Support for various GPT model variants

### VLLM
High-throughput LLM inference server optimized for serving.
- **Scalable Serving**: High-performance serving for multiple concurrent users
- **Model Support**: Wide range of open-source models
- **Optimization**: Memory-efficient inference with optimization techniques

### SGLang
Structured generation language for efficient LLM inference.
- **Efficient Generation**: Optimized for structured output generation
- **Controlled Generation**: Precise control over generated content
- **Performance**: Efficient inference for specific use cases

## Configuration Examples

### Basic Configuration with Ollama (Defaults to Offline)
```xml
<hackerbot>
  <name>TrainingBot</name>
  <llm_provider>ollama</llm_provider>
  <ollama_model>llama2</ollama_model>
  <system_prompt>Helpful cybersecurity instructor</system_prompt>
  <get_shell>false</get_shell>
  
  <!-- RAG + CAG is enabled by default with offline operation -->
  <rag_cag_enabled>true</rag_cag_enabled>
  
  <attacks>
    <attack>
      <prompt>Introduction to port scanning</prompt>
      <system_prompt>Beginner-friendly instructor persona</system_prompt>
    </attack>
  </attacks>
</hackerbot>
```

### Configuration with RAG + CAG Enabled (Defaults to Offline)
```xml
<hackerbot>
  <name>CybersecurityRAGBot</name>
  <llm_provider>ollama</llm_provider>
  <ollama_model>gemma3:1b</ollama_model>
  <system_prompt>You are an advanced cybersecurity training assistant with access to comprehensive knowledge bases. You can provide detailed explanations about attack patterns, malware families, security tools, and defense strategies. Use your enhanced context to provide accurate, up-to-date information and always cite specific sources when possible.</system_prompt>
  <get_shell>false</get_shell>
  
  <!-- RAG + CAG Configuration (enabled by default) -->
  <rag_cag_enabled>true</rag_cag_enabled>
  
  <!-- Individual system control (optional - defaults to both enabled) -->
  <rag_enabled>true</rag_enabled>
  <cag_enabled>true</cag_enabled>
  
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
  
  <attacks>
    <attack>
      <prompt>Let's start with credential dumping attacks. What are the main techniques used by attackers to steal credentials from Windows systems?</prompt>
      <system_prompt>You are a cybersecurity expert specializing in credential access attacks. Focus on providing detailed technical explanations about credential dumping techniques, tools like Mimikatz, and defensive strategies.</system_prompt>
      <quiz>
        <question>What is the primary mechanism that Mimikatz uses to extract credentials from Windows systems?</question>
        <answer>LSASS memory access</answer>
        <correct_answer_response>Correct! Mimikatz primarily accesses the Local Security Authority Subsystem Service (LSASS) process memory to extract credential material. This technique is classified as T1003.001 in the MITRE ATT&CK framework.</correct_answer_response>
      </quiz>
    </attack>
  </attacks>
</hackerbot>
```

### Offline Configuration (Now Default)
```xml
<hackerbot>
  <name>OfflineCyberBot</name>
  <llm_provider>ollama</llm_provider>
  <ollama_model>nomic-embed-text</ollama_model>
  <system_prompt>You are an offline cybersecurity training assistant. All your knowledge comes from pre-downloaded cybersecurity knowledge bases including MITRE ATT&CK, CVE databases, and security tools. Provide comprehensive explanations based on your available knowledge.</system_prompt>
  <get_shell>false</get_shell>
  
  <!-- RAG + CAG Configuration (now defaults to offline) -->
  <rag_cag_enabled>true</rag_cag_enabled>
  
  <!-- Individual system control examples -->
  <rag_enabled>true</rag_enabled>
  <cag_enabled>true</cag_enabled>
  
  <rag_cag_config>
    <rag>
      <max_rag_results>5</max_rag_results>
      <include_rag_context>true</include_rag_context>
      <collection_name>offline_cybersecurity</collection_name>
    </rag>
    
    <cag>
      <max_cag_depth>2</max_cag_depth>
      <max_cag_nodes>15</max_cag_nodes>
      <include_cag_context>true</include_cag_context>
    </cag>
  </rag_cag_config>
  
  <entity_extraction_enabled>true</entity_extraction_enabled>
  <entity_types>ip_address, url, hash, filename</entity_types>
</hackerbot>
```

### Enhanced Knowledge Sources Configuration
```xml
<hackerbot>
  <name>EnhancedKnowledgeBot</name>
  <llm_provider>ollama</llm_provider>
  <ollama_model>gemma3:1b</ollama_model>
  <system_prompt>You are an advanced cybersecurity training assistant with access to comprehensive knowledge bases including MITRE ATT&CK, Unix/Linux man pages, and custom markdown documentation. You can provide detailed explanations about attack patterns, security tools, command usage, and defense strategies.</system_prompt>
  <get_shell>false</get_shell>
  
  <!-- RAG + CAG Configuration -->
  <rag_cag_enabled>true</rag_cag_enabled>
  <rag_enabled>true</rag_enabled>
  <cag_enabled>true</cag_enabled>
  
  <!-- Enhanced Knowledge Sources Configuration -->
  <knowledge_sources>
    <!-- MITRE ATT&CK Framework (always included by default) -->
    <source>
      <type>mitre_attack</type>
      <name>mitre_attack</name>
      <enabled>true</enabled>
      <description>MITRE ATT&CK framework knowledge base</description>
      <priority>1</priority>
    </source>
    
    <!-- Man Pages Knowledge Source -->
    <source>
      <type>man_pages</type>
      <name>security_tools</name>
      <enabled>true</enabled>
      <description>Unix/Linux security tools man pages</description>
      <priority>2</priority>
      <man_pages>
        <man_page>
          <name>nmap</name>
          <section>1</section>
          <collection_name>network_scanning_tools</collection_name>
        </man_page>
        <man_page>
          <name>iptables</name>
          <section>8</section>
          <collection_name>firewall_tools</collection_name>
        </man_page>
        <man_page>
          <name>tcpdump</name>
          <section>1</section>
          <collection_name>network_analysis</collection_name>
        </man_page>
        <man_page>
          <name>ssh</name>
          <section>1</section>
          <collection_name>secure_communication</collection_name>
        </man_page>
        <man_page>
          <name>openssl</name>
          <section>1</section>
          <collection_name>cryptography_tools</collection_name>
        </man_page>
      </man_pages>
    </source>
    
    <!-- Markdown Files Knowledge Source -->
    <source>
      <type>markdown_files</type>
      <name>cybersecurity_docs</name>
      <enabled>true</enabled>
      <description>Custom cybersecurity documentation in markdown format</description>
      <priority>3</priority>
      <markdown_files>
        <markdown_file>
          <path>docs/network_security_best_practices.md</path>
          <collection_name>security_guidelines</collection_name>
          <tags>
            <tag>network-security</tag>
            <tag>best-practices</tag>
            <tag>defense</tag>
          </tags>
        </markdown_file>
        <markdown_file>
          <path>docs/incident_response_procedures.md</path>
          <collection_name>incident_response</collection_name>
          <tags>
            <tag>incident-response</tag>
            <tag>procedures</tag>
            <tag>forensics</tag>
          </tags>
        </markdown_file>
        <directory>
          <path>docs/threat_intelligence/</path>
          <pattern>*.md</pattern>
          <collection_name>threat_intelligence</collection_name>
        </directory>
      </markdown_files>
    </source>
  </knowledge_sources>
  
  <entity_extraction_enabled>true</entity_extraction_enabled>
  <entity_types>ip_address, url, hash, filename, port, email, domain, command, tool_name</entity_types>
</hackerbot>
```

### RAG-Only Configuration
```xml
<hackerbot>
  <name>DocumentRetrievalBot</name>
  <llm_provider>ollama</llm_provider>
  <ollama_model>gemma3:1b</ollama_model>
  <system_prompt>You are a cybersecurity document retrieval assistant. I focus on retrieving relevant documents from comprehensive knowledge bases to provide accurate information about attack patterns, vulnerabilities, and security tools.</system_prompt>
  <get_shell>false</get_shell>
  
  <!-- RAG + CAG Configuration -->
  <rag_cag_enabled>true</rag_cag_enabled>
  
  <!-- Individual system control: RAG only -->
  <rag_enabled>true</rag_enabled>
  <cag_enabled>false</cag_enabled>
  
  <rag_cag_config>
    <rag>
      <max_rag_results>10</max_rag_results>
      <include_rag_context>true</include_rag_context>
      <collection_name>cybersecurity_documents</collection_name>
    </rag>
    
    <cag>
      <max_cag_depth>0</max_cag_depth>
      <max_cag_nodes>0</max_cag_nodes>
      <include_cag_context>false</include_cag_context>
    </cag>
  </rag_cag_config>
  
  <entity_extraction_enabled>false</entity_extraction_enabled>
</hackerbot>
```

### CAG-Only Configuration
```xml
<hackerbot>
  <name>EntityAnalysisBot</name>
  <llm_provider>ollama</llm_provider>
  <ollama_model>gemma3:1b</ollama_model>
  <system_prompt>You are a cybersecurity entity analysis assistant. I specialize in extracting and analyzing entities like IP addresses, URLs, hashes, and filenames, then understanding their relationships within cybersecurity knowledge graphs.</system_prompt>
  <get_shell>false</get_shell>
  
  <!-- RAG + CAG Configuration -->
  <rag_cag_enabled>true</rag_cag_enabled>
  
  <!-- Individual system control: CAG only -->
  <rag_enabled>false</rag_enabled>
  <cag_enabled>true</cag_enabled>
  
  <rag_cag_config>
    <rag>
      <max_rag_results>0</max_rag_results>
      <include_rag_context>false</include_rag_context>
    </rag>
    
    <cag>
      <max_cag_depth>4</max_cag_depth>
      <max_cag_nodes>30</max_cag_nodes>
      <include_cag_context>true</include_cag_context>
    </cag>
  </rag_cag_config>
  
  <entity_extraction_enabled>true</entity_extraction_enabled>
  <entity_types>ip_address, url, hash, filename, port, email, domain, mac_address</entity_types>
</hackerbot>
```

### Configuration with OpenAI
```xml
<hackerbot>
  <name>GPTBot</name>
  <llm_provider>openai</llm_provider>
  <openai_api_key>YOUR_API_KEY_HERE</openai_api_key>
  <ollama_model>gpt-3.5-turbo</ollama_model>
  <system_prompt>Helpful cybersecurity instructor</system_prompt>
  <get_shell>false</get_shell>
</hackerbot>
```

### Configuration with VLLM
```xml
<hackerbot>
  <name>VLLMBot</name>
  <llm_provider>vllm</llm_provider>
  <vllm_host>localhost</vllm_host>
  <vllm_port>8000</vllm_port>
  <ollama_model>facebook/opt-125m</ollama_model>
  <system_prompt>Helpful cybersecurity instructor</system_prompt>
  <get_shell>false</get_shell>
</hackerbot>
```

### Configuration with SGLang
```xml
<hackerbot>
  <name>SGLangBot</name>
  <llm_provider>sglang</llm_provider>
  <sglang_host>localhost</sglang_host>
  <sglang_port>30000</sglang_port>
  <ollama_model>meta-llama/Llama-2-7b-chat-hf</ollama_model>
  <system_prompt>Helpful cybersecurity instructor</system_prompt>
  <get_shell>false</get_shell>
</hackerbot>
```

## Command-Line Usage

Start the system with:
```bash
ruby hackerbot.rb [OPTIONS]
```

Options:
- `--irc-server`, `-i HOST` - IRC server IP address (default: localhost)
- `--llm-provider`, `-l PROVIDER` - LLM provider: ollama, openai, vllm, sglang (default: ollama)
- `--ollama-host`, `-o HOST` - Ollama server host (default: localhost)
- `--ollama-port`, `-p PORT` - Ollama server port (default: 11434)
- `--ollama-model`, `-m MODEL` - Ollama model name (default: gemma3:1b)
- `--openai-api-key`, `-k KEY` - OpenAI API key
- `--vllm-host HOST` - VLLM server host (default: localhost)
- `--vllm-port PORT` - VLLM server port (default: 8000)
- `--sglang-host HOST` - SGLang server host (default: localhost)
- `--sglang-port PORT` - SGLang server port (default: 30000)
- `--streaming`, `-s true|false` - Enable/disable streaming (default: true)
- `--enable-rag-cag` - Enable RAG + CAG capabilities (default: true)
- `--rag-only` - Enable only RAG system (disables CAG)
- `--cag-only` - Enable only CAG system (disables RAG)
- `--offline` - Force offline mode (default: auto-detect)
- `--online` - Force online mode
- `--help`, `-h` - Show help message

### RAG + CAG Specific Options

When `--enable-rag-cag` is enabled (default), additional configuration options are available through the XML configuration file or environment variables:

```bash
# Enable RAG + CAG with auto-detection (default behavior)
ruby hackerbot.rb

# Enable only RAG system
ruby hackerbot.rb --rag-only

# Enable only CAG system
ruby hackerbot.rb --cag-only

# Force offline mode (default is auto-detect)
ruby hackerbot.rb --offline

# Force online mode
ruby hackerbot.rb --online

# Setup offline mode (one-time initial setup)
ruby setup_offline_rag_cag.rb

# Check offline status
ruby rag_cag_offline_config.rb status

# Start offline mode
./start_offline.sh
```

Connect via IRC client to interact with bots in channels named after each bot or in the general `#bots` channel.

## Training Applications

### Knowledge-Enhanced Training
- **Attack Pattern Analysis**: Detailed explanations using MITRE ATT&CK framework
- **Vulnerability Assessment**: Context-aware CVE information and remediation guidance
- **Tool Recommendations**: Intelligent security tool suggestions based on context
- **Defense Strategies**: Knowledge-based defense recommendations and best practices
- **Threat Intelligence**: Entity relationships and attack pattern connections

### Red Team Exercises
- Simulate adversary behaviors with knowledge-based context
- Attack progression with MITRE ATT&CK technique explanations
- Tool selection guidance with performance characteristics
- Evasion tactics and defense countermeasure explanations

### Blue Team Training
- Practice detection with knowledge-based threat indicators
- Response procedures with context-aware recommendations
- Log analysis with entity relationship mapping
- Incident response with knowledge graph traversal

### Social Engineering Defense
- Learn to recognize manipulation with pattern analysis
- Phishing detection with entity extraction and URL analysis
- Social engineering tactics with historical context
- Defense strategies with knowledge-based recommendations

### AI Security Exercises
- Prompt injection attack training with knowledge base context
- LLM security awareness with vulnerability pattern explanations
- Responsible AI interaction practices with ethical guidelines
- AI vulnerability assessment with comprehensive framework references

### Incident Response Drills
- Practice structured response procedures with knowledge-based guidance
- Scenario-based training with real-world context
- Decision-making with relationship mapping between entities
- Post-incident analysis with lessons learned integration

### Offline Training Capabilities
- **Air-Gapped Training**: Complete functionality without internet connectivity
- **Secure Environments**: Deploy in classified or restricted networks
- **Field Deployments**: Mobile training units with limited connectivity
- **Compliance Training**: Meet data sovereignty requirements
- **Cost-Effective Operation**: No cloud service fees or API dependencies

## Documentation and Resources

- **Implementation Guide**: `README_ENHANCED_KNOWLEDGE.md` - Comprehensive guide to enhanced knowledge sources
- **Demo Script**: `demo_enhanced_knowledge.rb` - Interactive demonstration of enhanced capabilities
- **Configuration Examples**: 
  - `config/example_enhanced_knowledge_bot.xml` - Complete example with man pages and markdown files
  - `config/example_rag_cag_bot.xml` - Traditional RAG/CAG configuration
- **Example Documentation**: 
  - `docs/network_security_best_practices.md` - Network security guidelines
  - `docs/incident_response_procedures.md` - Incident response playbooks
  - `docs/threat_intelligence/apt_groups.md` - Threat intelligence information

## Project Structure

```
opt_hackerbot/
├── rag_cag_manager.rb                    # Unified RAG + CAG manager
├── knowledge_bases/                       # Knowledge base collections and sources
│   ├── base_knowledge_source.rb          # Base interface for knowledge sources
│   ├── knowledge_source_manager.rb       # Manager for multiple knowledge sources
│   ├── mitre_attack_knowledge.rb         # MITRE ATT&CK framework
│   ├── sources/                          # Knowledge source implementations
│   │   ├── man_pages/                    # Man page knowledge source
│   │   │   └── man_page_knowledge.rb     # Man page processing and integration
│   │   └── markdown_files/               # Markdown file knowledge source
│   │       └── markdown_knowledge.rb     # Markdown file processing and integration
│   └── utils/                            # Knowledge processing utilities
│       ├── man_page_processor.rb         # Man page extraction and processing
│       └── markdown_processor.rb         # Markdown file parsing and analysis
├── rag/                                   # RAG system components
│   ├── rag_manager.rb                     # RAG operations coordinator
│   ├── vector_db_interface.rb            # Vector database base interface
│   ├── embedding_service_interface.rb    # Embedding service base interface
│   ├── chromadb_client.rb               # In-memory ChromaDB client
│   ├── chromadb_offline_client.rb       # Offline persistent ChromaDB
│   ├── openai_embedding_client.rb        # OpenAI embedding service
│   ├── ollama_embedding_client.rb        # Ollama embedding service
│   └── ollama_embedding_offline_client.rb # Offline Ollama embedding
├── cag/                                   # CAG system components
│   ├── cag_manager.rb                     # CAG operations coordinator
│   ├── knowledge_graph_interface.rb       # Knowledge graph base interface
│   ├── in_memory_graph_client.rb          # In-memory knowledge graph
│   └── in_memory_graph_offline_client.rb # Offline persistent graph
├── config/                                # Bot configuration files
│   ├── example_rag_cag_bot.xml           # Example RAG + CAG bot config
│   └── example_enhanced_knowledge_bot.xml # Example with man pages and markdown files
├── docs/                                  # Example documentation files
│   ├── network_security_best_practices.md # Network security guidelines
│   ├── incident_response_procedures.md   # Incident response procedures
│   └── threat_intelligence/               # Threat intelligence documents
│       └── apt_groups.md                 # APT groups and threat actors
├── cache/                                 # Cache directories for knowledge sources
│   ├── man_pages/                         # Cached man page content
│   └── markdown/                          # Cached markdown file content
├── test/                                  # Test suites
│   ├── test_rag_cag_system.rb            # RAG + CAG system tests
│   ├── rag/                               # RAG component tests
│   └── cag/                               # CAG component tests
├── setup_offline_rag_cag.rb               # Offline setup script
├── rag_cag_offline_config.rb             # Offline configuration manager
├── demo_rag_cag.rb                       # Interactive demonstration
├── demo_enhanced_knowledge.rb            # Enhanced knowledge sources demo
├── start_offline.sh                      # Offline startup script
├── RAG_CAG_IMPLEMENTATION_SUMMARY.md     # Implementation documentation
└── README_ENHANCED_KNOWLEDGE.md          # Enhanced knowledge sources guide
```

This framework provides a flexible platform for creating engaging, interactive cybersecurity training experiences that combine traditional attack simulation with modern AI-powered educational techniques using multiple LLM backends and advanced knowledge retrieval systems. The RAG + CAG integration enables intelligent, context-aware conversations with comprehensive cybersecurity knowledge, both online and offline.

**Enhanced Knowledge Sources**: The system now supports man pages and markdown files as knowledge sources, allowing bots to provide detailed explanations about Unix/Linux commands, security tools, and custom documentation. Knowledge sources are configured through XML and can be organized into logical collections with customizable priorities and processing options.