# Hackerbot Agents System

Hackerbot is a Ruby-based IRC bot framework designed for cybersecurity training exercises. It combines traditional attack simulation with modern AI capabilities through integration with multiple LLM providers.

## Overview

The system consists of intelligent IRC bots that can guide users through progressive cybersecurity challenges while maintaining contextual conversations using LLMs. Each bot can adapt its personality and behavior based on the current training scenario. Hackerbot now supports multiple LLM backends including Ollama, OpenAI, VLLM, and SGLang.

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

### Configuration System
Bots are configured through XML files located in the `config/` directory:
- `<name>` - Unique identifier for the bot
- `<llm_provider>` - LLM provider to use (ollama, openai, vllm, sglang)
- `<get_shell>` - Shell access configuration
- `<messages>` - Static response templates
- `<attacks>` - Progressive challenge scenarios

### LLM Integration
- Support for multiple LLM providers: Ollama, OpenAI, VLLM, SGLang
- Per-user chat history management for contextual conversations
- Streaming responses for real-time interaction
- Per-attack system prompts for dynamic personality changes

## Key Features

### Multi-Bot Management
- Single manager controls multiple concurrent bot instances
- Each bot operates in its own IRC channels
- Independent configuration per bot

### Progressive Attack System
- Structured learning paths through numbered attack scenarios
- Navigation commands (`next`, `previous`, `goto`)
- Conditional progression based on user responses
- Automated verification of correct answers

### AI-Powered Conversations
- Natural language understanding through multiple LLM providers
- Context retention through per-user chat history
- Dynamic personality adaptation per training stage
- Real-time streaming responses for better interactivity

### Interactive Learning
- Quiz-based knowledge verification
- Hands-on shell command execution
- Immediate feedback mechanisms
- Comprehensive help system

## Agent Capabilities

### Social Engineering Training
Agents can role-play various personas:
- Gullible customer service representatives
- Naive IT administrators
- Trusting employees with sensitive access

### AI Security Exercises
Agents simulate vulnerable AI systems for:
- Prompt injection attack training
- LLM security awareness
- Responsible AI interaction practices

### Traditional Cybersecurity Drills
Agents guide users through:
- Network reconnaissance
- Exploitation techniques
- Post-exploitation activities

## Supported LLM Providers

### Ollama
Local LLM inference engine with support for many models.

### OpenAI
Cloud-based API access to GPT models with API key authentication.

### VLLM
High-throughput LLM inference server optimized for serving.

### SGLang
Structured generation language for efficient LLM inference.

## Configuration Examples

### Basic Configuration with Ollama
```xml
<hackerbot>
  <name>TrainingBot</name>
  <llm_provider>ollama</llm_provider>
  <ollama_model>llama2</ollama_model>
  <system_prompt>Helpful cybersecurity instructor</system_prompt>
  <get_shell>false</get_shell>
  
  <attacks>
    <attack>
      <prompt>Introduction to port scanning</prompt>
      <system_prompt>Beginner-friendly instructor persona</system_prompt>
    </attack>
  </attacks>
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
- `--help`, `-h` - Show help message

Connect via IRC client to interact with bots in channels named after each bot or in the general `#bots` channel.

## Training Applications

- **Red Team Exercises** - Simulate adversary behaviors
- **Blue Team Training** - Practice detection and response
- **Social Engineering Defense** - Learn to recognize manipulation
- **AI Security Awareness** - Understand LLM vulnerabilities
- **Incident Response Drills** - Practice structured response procedures

This framework provides a flexible platform for creating engaging, interactive cybersecurity training experiences that combine traditional attack simulation with modern AI-powered educational techniques using multiple LLM backends.