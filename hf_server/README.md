# Hugging Face Integration for Hackerbot

This directory contains the Hugging Face integration for Hackerbot, enabling local inference using the Llama 3.2 model through the Transformers library.

## Overview

The Hugging Face integration consists of:
- **Python HTTP Server** (`hf_inference_server.py`) - Serves Llama 3.2 model via HTTP API
- **Ruby Client** (`../providers/huggingface_client.rb`) - Ruby client that communicates with the Python server
- **Startup Script** (`start_server.py`) - Handles model download and server initialization

## Features

- ✅ Local Llama 3.2 inference (no external API dependencies)
- ✅ Automatic model downloading and caching
- ✅ GPU acceleration (CUDA/MPS) when available
- ✅ Streaming and non-streaming responses
- ✅ Configurable temperature and token limits
- ✅ OpenAI-compatible chat completion endpoint
- ✅ Health check and model info endpoints
- ✅ Graceful shutdown handling

## Quick Start

### 1. Enter Development Environment
```bash
cd opt_hackerbot
nix develop
```

### 2. Start the Hugging Face Server
```bash
make start-hf
```

This will:
- Check dependencies
- Download Llama 3.2 model (first time only)
- Start the inference server on localhost:8899

### 3. Start Hackerbot with Hugging Face
```bash
make bot-hf
```

Or with RAG + CAG enabled:
```bash
make bot-hf-rag-cag
```

## Model Information

**Default Model**: `TinyLlama/TinyLlama-1.1B-Chat-v1.0`

- **Size**: ~1.1B parameters (very lightweight, ideal for local inference)
- **Architecture**: Transformer-based language model
- **License**: Apache 2.0 License (fully open source)
- **Hardware Requirements**: 
  - CPU: Any modern CPU (functional performance)
  - GPU: Optional for better performance
  - RAM: 4GB+ recommended
  - Storage: ~2GB for model files
- **Advantages**: No authentication required, faster download, lower resource usage

## API Endpoints

### Health Check
```bash
GET http://localhost:8899/health
```

Response:
```json
{
  "status": "healthy",
  "model_loaded": true,
  "model": "meta-llama/Llama-3.2-3B-Instruct",
  "device": "cuda"
}
```

### Generate Text
```bash
POST http://localhost:8899/generate
Content-Type: application/json

{
  "prompt": "Explain what a firewall is",
  "max_tokens": 150,
  "temperature": 0.7,
  "stream": false
}
```

### Chat Completion (OpenAI-compatible)
```bash
POST http://localhost:8899/chat
Content-Type: application/json

{
  "messages": [
    {"role": "system", "content": "You are a cybersecurity expert."},
    {"role": "user", "content": "What is penetration testing?"}
  ],
  "max_tokens": 150,
  "temperature": 0.7,
  "stream": false
}
```

## Configuration

### Server Configuration
The server can be configured with command-line arguments:

```bash
python3 hf_inference_server.py \
  --model TinyLlama/TinyLlama-1.1B-Chat-v1.0 \
  --host 127.0.0.1 \
  --port 8899 \
  --device auto
```

### Client Configuration
In your bot configuration XML:

```xml
<llm_provider>huggingface</llm_provider>
<llm_config>
    <host>127.0.0.1</host>
    <port>8899</port>
    <model>meta-llama/Llama-3.2-3B-Instruct</model>
    <max_tokens>150</max_tokens>
    <temperature>0.7</temperature>
    <streaming>true</streaming>
    <timeout>300</timeout>
</llm_config>
```

## Management Commands

### Using Make Commands
```bash
make start-hf      # Start Hugging Face server
make stop-hf       # Stop Hugging Face server
make restart-hf    # Restart Hugging Face server
make status-hf     # Check server status
```

### Manual Server Management
```bash
# Start server
cd hf_server
python3 hf_inference_server.py

# Start with specific device
python3 hf_inference_server.py --device cuda

# Start without loading model immediately
python3 hf_inference_server.py --no-load
```

## Testing

### Run Demo Script
```bash
nix develop --command ruby demo_huggingface.rb
```

This will test:
- Server connection
- Basic text generation
- Streaming responses
- Cybersecurity knowledge
- Performance with different settings

### Manual Testing
```bash
# Test health endpoint
curl http://localhost:8899/health

# Test generation
curl -X POST http://localhost:8899/generate \
  -H "Content-Type: application/json" \
  -d '{"prompt": "Hello, world!", "max_tokens": 50}'
```

## Model Storage

Models are cached in `hf_server/models/` by default. The cache structure follows Hugging Face's format:

```
hf_server/models/
└── --files--/
    └--meta-llama--Llama-3.2-3B-Instruct/
        ├── config.json
        ├── pytorch_model.bin
        ├── tokenizer.json
        └── ...
```

### Managing Model Cache
```bash
# Check cache size
du -sh hf_server/models/

# Clear cache (use with caution)
rm -rf hf_server/models/*
```

## Performance Optimization

### GPU Acceleration
The server automatically detects and uses available hardware:
- **CUDA**: For NVIDIA GPUs
- **MPS**: For Apple Silicon (M1/M2/M3)
- **CPU**: Fallback option

### Memory Management
- Model is loaded with appropriate precision (float16 for GPU, float32 for CPU)
- Automatic memory mapping for large models
- Garbage collection handles memory cleanup

### Performance Tips
1. **Use GPU**: Significantly faster inference
2. **Adjust max_tokens**: Lower values = faster responses
3. **Batching**: Not supported in current implementation
4. **Temperature**: Lower values = faster generation

## Troubleshooting

### Common Issues

#### Server Won't Start
```bash
# Check if port is in use
lsof -i :8899

# Check server logs
tail -f /tmp/hf_server.log
```

#### Model Download Fails
- Check internet connection
- Verify Hugging Face access (some models require approval)
- Check available disk space

#### Out of Memory Errors
- Use CPU instead of GPU: `--device cpu`
- Reduce model size (use 1B instead of 3B)
- Close other memory-intensive applications

#### Slow Inference
- Ensure GPU is being used
- Check if system is under heavy load
- Consider reducing max_tokens

### Debug Mode
Start server with debug logging:
```bash
python3 hf_inference_server.py --device auto
```

Check system resources:
```bash
# GPU usage (NVIDIA)
nvidia-smi

# Memory usage
free -h

# Disk usage
df -h
```

## Integration with Existing Features

The Hugging Face client integrates seamlessly with Hackerbot's existing features:

- **RAG (Retrieval-Augmented Generation)**: Enhances responses with knowledge base
- **CAG (Context-Aware Generation)**: Provides entity-aware responses
- **Multiple Personalities**: Can be used with different bot personalities
- **Streaming Support**: Real-time response generation
- **Error Handling**: Graceful fallback on server failures

## Advanced Usage

### Custom Models
You can use different open models by modifying the configuration:

```xml
<model>TinyLlama/TinyLlama-1.1B-Chat-v1.0</model>
<model>microsoft/DialoGPT-medium</model>
<model>distilbert-base-uncased</model>
```

For gated models like Llama, you'll need to authenticate with Hugging Face:
```bash
# Login to Hugging Face (requires account and approval)
source hf_env/bin/activate
huggingface-cli login
```

Note: Larger models require more memory and compute resources. TinyLlama is optimized for local use without authentication.

### Batch Processing
For batch processing, consider implementing a queue system or using the server directly via HTTP API.

### Integration with External Tools
The HTTP API can be called from any programming language, making it easy to integrate with external tools and services.

## Security Considerations

- **Local Inference**: No data sent to external services
- **Network Access**: Server only listens on localhost by default
- **Model Security**: Models are downloaded from official Hugging Face repository
- **Input Validation**: Basic validation implemented in server

## Contributing

To extend the Hugging Face integration:

1. **Add New Models**: Update configuration options
2. **Enhance API**: Add new endpoints or features
3. **Improve Performance**: Optimize inference speed
4. **Add Monitoring**: Implement metrics and logging

## License

This integration follows the same license as the main Hackerbot project. TinyLlama uses the Apache 2.0 License (fully open source).