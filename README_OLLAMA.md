# Hackerbot with Ollama Integration

This version of Hackerbot has been updated to use Ollama LLM instead of the ALICE AIML chatbot for natural language responses.

## Changes Made

1. **Replaced ALICE with Ollama**: Removed dependency on `programr` gem and ALICE AIML files
2. **Added OllamaClient class**: New HTTP client for communicating with Ollama API
3. **Updated message handling**: Now uses Ollama's generate API instead of AIML pattern matching
4. **Added configuration options**: Support for customizing Ollama host, port, and model per bot

## Requirements

- Ruby with standard libraries (no additional gems needed)
- Ollama running locally or remotely
- A compatible LLM model installed in Ollama (default: llama2)

## Installation

1. Install Ollama: https://ollama.ai/
2. Pull a model: `ollama pull llama2`
3. Start Ollama: `ollama serve`

## Usage

### Basic Usage
```bash
ruby hackerbot.rb
```

### With Custom Ollama Settings
```bash
ruby hackerbot.rb --ollama-host localhost --ollama-port 11434 --ollama-model llama2
```

### Command Line Options
- `--irc-server host`: IRC server address (default: localhost)
- `--ollama-host host`: Ollama server host (default: localhost)
- `--ollama-port port`: Ollama server port (default: 11434)
- `--ollama-model model`: Ollama model name (default: llama2)

## Configuration

### Per-Bot Configuration
You can configure Ollama settings per bot in the XML configuration:

```xml
<hackerbot>
  <name>MyBot</name>
  <ollama_model>llama2</ollama_model>
  <ollama_host>localhost</ollama_host>
  <ollama_port>11434</ollama_port>
  <!-- ... other configuration ... -->
</hackerbot>
```

### Bot Configuration Priority
1. XML configuration (highest priority)
2. Command line arguments
3. Default values (lowest priority)

## Example Configuration

See `config/example_ollama.xml` for a complete example configuration.

## Features

- **Natural Language Processing**: Uses modern LLM for more natural conversations
- **Configurable Models**: Support for any model available in Ollama
- **Fallback Responses**: Graceful handling when Ollama is unavailable
- **Backward Compatibility**: Existing bot configurations still work
- **Error Handling**: Robust error handling for network issues

## Troubleshooting

### Ollama Connection Issues
- Ensure Ollama is running: `ollama serve`
- Check if the model is installed: `ollama list`
- Verify network connectivity to Ollama server
- Check firewall settings if using remote Ollama

### Model Issues
- Pull the required model: `ollama pull modelname`
- Verify model name in configuration
- Check Ollama logs for model-specific errors

## Migration from ALICE

Existing bot configurations will continue to work. The `AIML_chatbot_rules` field is kept for compatibility but is no longer used. You can optionally add Ollama-specific configuration:

```xml
<!-- Optional: Add these fields to customize Ollama settings -->
<ollama_model>llama2</ollama_model>
<ollama_host>localhost</ollama_host>
<ollama_port>11434</ollama_port>
```

## Performance Notes

- First response may be slower due to model loading
- Response quality depends on the chosen model
- Consider using smaller models for faster responses
- Network latency affects response time for remote Ollama instances 