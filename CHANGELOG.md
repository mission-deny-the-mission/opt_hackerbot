# Changelog - ALICE to Ollama Migration

## Version 2.0.0 - Ollama Integration

### Major Changes
- **Replaced ALICE AIML chatbot with Ollama LLM integration**
- **Removed dependency on `programr` gem**
- **Added modern LLM capabilities for natural language processing**

### New Features
- **OllamaClient class**: HTTP client for communicating with Ollama API
- **Configurable models**: Support for any model available in Ollama
- **Per-bot configuration**: Custom Ollama settings per bot instance
- **Command line options**: Global Ollama configuration via CLI
- **Connection testing**: Automatic validation of Ollama connectivity
- **Error handling**: Robust error handling for network and API issues

### Configuration Changes
- **New XML fields**:
  - `<ollama_model>`: Specify the Ollama model to use
  - `<ollama_host>`: Ollama server hostname
  - `<ollama_port>`: Ollama server port
- **Legacy support**: `AIML_chatbot_rules` field kept for compatibility but unused

### Command Line Options
- `--ollama-host`: Set Ollama server host (default: localhost)
- `--ollama-port`: Set Ollama server port (default: 11434)
- `--ollama-model`: Set default Ollama model (default: llama2)

### Files Added
- `config/example_ollama.xml`: Example configuration with Ollama settings
- `README_OLLAMA.md`: Comprehensive documentation
- `test_ollama.rb`: Integration test script
- `setup_ollama.sh`: Automated setup script
- `CHANGELOG.md`: This changelog

### Files Modified
- `hackerbot.rb`: Complete rewrite of chatbot integration
  - Removed `require 'programr'`
  - Added `require 'net/http'` and `require 'json'`
  - Added `OllamaClient` class
  - Updated bot initialization logic
  - Modified message handling to use Ollama API
  - Added command line argument parsing for Ollama settings

### Backward Compatibility
- Existing bot configurations continue to work
- AIML files are no longer used but don't cause errors
- All existing IRC bot functionality preserved
- Attack system unchanged

### Requirements
- **New**: Ollama server running locally or remotely
- **New**: Compatible LLM model installed in Ollama
- **Removed**: `programr` gem dependency
- **Removed**: AIML file dependencies

### Migration Notes
1. Install Ollama: `curl -fsSL https://ollama.ai/install.sh | sh`
2. Pull a model: `ollama pull llama2`
3. Start Ollama: `ollama serve`
4. Optionally add Ollama configuration to existing XML files
5. Run with: `ruby hackerbot.rb`

### Performance Impact
- **Positive**: More natural and contextual responses
- **Positive**: Support for modern language models
- **Consideration**: First response may be slower due to model loading
- **Consideration**: Network latency for remote Ollama instances 