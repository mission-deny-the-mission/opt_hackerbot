#!/usr/bin/env python3
"""
Hugging Face Inference Server for Hackerbot
Provides HTTP API for local Llama 3.2 inference
"""

import os
import json
import logging
import threading
import time
from typing import Dict, Any, Optional, Generator
from flask import Flask, request, jsonify, Response
from flask_cors import CORS
import torch
from transformers import AutoTokenizer, AutoModelForCausalLM, TextIteratorStreamer

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class HuggingFaceInferenceServer:
    def __init__(self, model_name: str = "EleutherAI/gpt-neo-125m",
                 host: str = "127.0.0.1", port: int = 8899,
                 device: str = "auto"):
        self.model_name = model_name
        self.host = host
        self.port = port
        self.device = self._determine_device(device)
        self.model = None
        self.tokenizer = None
        self.app = Flask(__name__)
        CORS(self.app)
        self._setup_routes()
        self.model_loaded = False

    def _determine_device(self, device: str) -> str:
        """Determine the best device for inference"""
        if device == "auto":
            if torch.cuda.is_available():
                device = "cuda"
                logger.info(f"Using CUDA: {torch.cuda.get_device_name()}")
            elif torch.backends.mps.is_available():
                device = "mps"
                logger.info("Using MPS (Apple Silicon)")
            else:
                device = "cpu"
                logger.info("Using CPU")
        return device

    def load_model(self):
        """Load the model and tokenizer"""
        try:
            logger.info(f"Loading model: {self.model_name}")
            logger.info(f"Using device: {self.device}")

            # Create models directory if it doesn't exist
            os.makedirs("models", exist_ok=True)

            # Load tokenizer
            self.tokenizer = AutoTokenizer.from_pretrained(
                self.model_name,
                cache_dir="./models",
                trust_remote_code=True
            )

            if self.tokenizer.pad_token is None:
                self.tokenizer.pad_token = self.tokenizer.eos_token

            # Load model
            self.model = AutoModelForCausalLM.from_pretrained(
                self.model_name,
                cache_dir="./models",
                torch_dtype=torch.float16 if self.device != "cpu" else torch.float32,
                device_map="auto" if self.device == "cuda" else None,
                trust_remote_code=True
            )

            if self.device == "cpu":
                self.model = self.model.to(self.device)

            self.model_loaded = True
            logger.info("Model loaded successfully!")
            logger.info(f"Model parameters: {sum(p.numel() for p in self.model.parameters()):,}")

        except Exception as e:
            logger.error(f"Failed to load model: {e}")
            raise

    def _setup_routes(self):
        """Setup Flask routes"""

        @self.app.route('/health', methods=['GET'])
        def health_check():
            """Health check endpoint"""
            return jsonify({
                "status": "healthy",
                "model_loaded": self.model_loaded,
                "model": self.model_name,
                "device": self.device
            })

        @self.app.route('/models', methods=['GET'])
        def list_models():
            """List available models"""
            return jsonify({
                "current_model": self.model_name,
                "loaded": self.model_loaded,
                "device": self.device
            })

        @self.app.route('/generate', methods=['POST'])
        def generate():
            """Generate text response"""
            try:
                if not self.model_loaded:
                    return jsonify({"error": "Model not loaded"}), 503

                data = request.get_json()
                prompt = data.get('prompt', '')
                max_tokens = data.get('max_tokens', 150)
                temperature = data.get('temperature', 0.7)
                stream = data.get('stream', False)

                if not prompt:
                    return jsonify({"error": "Prompt is required"}), 400

                if stream:
                    return Response(
                        self._generate_stream(prompt, max_tokens, temperature),
                        mimetype='text/plain'
                    )
                else:
                    response_text = self._generate_response(prompt, max_tokens, temperature)
                    return jsonify({"response": response_text})

            except Exception as e:
                logger.error(f"Generation error: {e}")
                return jsonify({"error": str(e)}), 500

        @self.app.route('/chat', methods=['POST'])
        def chat():
            """Chat completion endpoint (OpenAI-compatible)"""
            try:
                if not self.model_loaded:
                    return jsonify({"error": "Model not loaded"}), 503

                data = request.get_json()
                messages = data.get('messages', [])
                max_tokens = data.get('max_tokens', 150)
                temperature = data.get('temperature', 0.7)
                stream = data.get('stream', False)

                if not messages:
                    return jsonify({"error": "Messages are required"}), 400

                # Convert messages to prompt
                prompt = self._messages_to_prompt(messages)

                if stream:
                    return Response(
                        self._generate_stream_chat(prompt, max_tokens, temperature),
                        mimetype='text/event-stream'
                    )
                else:
                    response_text = self._generate_response(prompt, max_tokens, temperature)
                    return jsonify({
                        "choices": [{
                            "message": {
                                "role": "assistant",
                                "content": response_text
                            }
                        }]
                    })

            except Exception as e:
                logger.error(f"Chat error: {e}")
                return jsonify({"error": str(e)}), 500

    def _messages_to_prompt(self, messages: list) -> str:
        """Convert messages to prompt format"""
        # GPT-Neo simple chat template
        prompt = ""
        for message in messages:
            if message["role"] == "system":
                prompt += f"System: {message['content']}\n\n"
            elif message["role"] == "user":
                prompt += f"Human: {message['content']}\n\n"
            elif message["role"] == "assistant":
                prompt += f"Assistant: {message['content']}\n\n"

        prompt += "Assistant:"
        return prompt

    def _generate_response(self, prompt: str, max_tokens: int, temperature: float) -> str:
        """Generate response without streaming"""
        inputs = self.tokenizer(prompt, return_tensors="pt", padding=True)
        inputs = {k: v.to(self.device) for k, v in inputs.items()}

        with torch.no_grad():
            outputs = self.model.generate(
                **inputs,
                max_new_tokens=max_tokens,
                temperature=temperature,
                do_sample=temperature > 0,
                pad_token_id=self.tokenizer.eos_token_id,
                eos_token_id=self.tokenizer.eos_token_id,
            )

        # Decode only the generated part
        generated_text = self.tokenizer.decode(
            outputs[0][inputs['input_ids'].shape[1]:],
            skip_special_tokens=True
        ).strip()

        return generated_text

    def _generate_stream(self, prompt: str, max_tokens: int, temperature: float) -> Generator[str, None, None]:
        """Generate streaming response"""
        inputs = self.tokenizer(prompt, return_tensors="pt", padding=True)
        inputs = {k: v.to(self.device) for k, v in inputs.items()}

        streamer = TextIteratorStreamer(
            self.tokenizer,
            skip_special_tokens=True,
            skip_prompt=True
        )

        generation_kwargs = {
            **inputs,
            "max_new_tokens": max_tokens,
            "temperature": temperature,
            "do_sample": temperature > 0,
            "pad_token_id": self.tokenizer.eos_token_id,
            "eos_token_id": self.tokenizer.eos_token_id,
            "streamer": streamer
        }

        # Start generation in a separate thread
        thread = threading.Thread(target=self.model.generate, kwargs=generation_kwargs)
        thread.start()

        # Stream the output
        try:
            for text in streamer:
                if text:
                    yield text
        finally:
            thread.join()

    def _generate_stream_chat(self, prompt: str, max_tokens: int, temperature: float) -> Generator[str, None, None]:
        """Generate streaming response in OpenAI format"""
        for text in self._generate_stream(prompt, max_tokens, temperature):
            yield f"data: {json.dumps({'choices': [{'delta': {'content': text}}]})}\n\n"
        yield "data: [DONE]\n\n"

    def run(self, load_model_on_startup: bool = True):
        """Start the server"""
        if load_model_on_startup:
            self.load_model()

        logger.info(f"Starting Hugging Face inference server on {self.host}:{self.port}")
        self.app.run(host=self.host, port=self.port, debug=False)

def main():
    """Main entry point"""
    import argparse

    parser = argparse.ArgumentParser(description="Hugging Face Inference Server")
    parser.add_argument("--model", default="EleutherAI/gpt-neo-125m",
                       help="Model name to load")
    parser.add_argument("--host", default="127.0.0.1", help="Host to bind to")
    parser.add_argument("--port", type=int, default=8899, help="Port to bind to")
    parser.add_argument("--device", default="auto",
                       choices=["auto", "cpu", "cuda", "mps"],
                       help="Device to use for inference")
    parser.add_argument("--no-load", action="store_true",
                       help="Don't load model on startup")

    args = parser.parse_args()

    server = HuggingFaceInferenceServer(
        model_name=args.model,
        host=args.host,
        port=args.port,
        device=args.device
    )

    try:
        server.run(load_model_on_startup=not args.no_load)
    except KeyboardInterrupt:
        logger.info("Server stopped by user")
    except Exception as e:
        logger.error(f"Server error: {e}")
        return 1

    return 0

if __name__ == "__main__":
    exit(main())
