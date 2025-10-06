#!/usr/bin/env python3
"""
Simple test server for Hugging Face inference
Uses a tiny model for quick loading and testing
"""

import os
import sys
import json
import logging
from flask import Flask, request, jsonify
from transformers import AutoTokenizer, AutoModelForCausalLM
import torch

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class SimpleTestServer:
    def __init__(self, model_name: str = "hf-internal-testing/tiny-random-gpt2",
                 host: str = "127.0.0.1", port: int = 8899):
        self.model_name = model_name
        self.host = host
        self.port = port
        self.app = Flask(__name__)
        self.model = None
        self.tokenizer = None
        self.model_loaded = False
        self._setup_routes()

    def _setup_routes(self):
        """Setup Flask routes"""

        @self.app.route('/health', methods=['GET'])
        def health_check():
            """Health check endpoint"""
            return jsonify({
                "status": "healthy",
                "model_loaded": self.model_loaded,
                "model": self.model_name,
                "device": "cpu"
            })

        @self.app.route('/models', methods=['GET'])
        def list_models():
            """List available models"""
            return jsonify({
                "current_model": self.model_name,
                "loaded": self.model_loaded,
                "device": "cpu"
            })

        @self.app.route('/generate', methods=['POST'])
        def generate():
            """Generate text response"""
            try:
                if not self.model_loaded:
                    return jsonify({"error": "Model not loaded"}), 503

                data = request.get_json()
                prompt = data.get('prompt', '')
                max_tokens = data.get('max_tokens', 50)
                temperature = data.get('temperature', 0.7)

                if not prompt:
                    return jsonify({"error": "Prompt is required"}), 400

                # Simple generation
                inputs = self.tokenizer(prompt, return_tensors="pt")
                with torch.no_grad():
                    outputs = self.model.generate(
                        **inputs,
                        max_new_tokens=max_tokens,
                        do_sample=temperature > 0,
                        temperature=temperature if temperature > 0 else 1.0,
                        pad_token_id=self.tokenizer.eos_token_id
                    )

                # Decode only the generated part
                generated_text = self.tokenizer.decode(
                    outputs[0][inputs['input_ids'].shape[1]:],
                    skip_special_tokens=True
                ).strip()

                return jsonify({"response": generated_text})

            except Exception as e:
                logger.error(f"Generation error: {e}")
                return jsonify({"error": str(e)}), 500

        @self.app.route('/chat', methods=['POST'])
        def chat():
            """Chat completion endpoint"""
            try:
                if not self.model_loaded:
                    return jsonify({"error": "Model not loaded"}), 503

                data = request.get_json()
                messages = data.get('messages', [])
                max_tokens = data.get('max_tokens', 50)
                temperature = data.get('temperature', 0.7)

                if not messages:
                    return jsonify({"error": "Messages are required"}), 400

                # Convert messages to simple prompt
                prompt = ""
                for message in messages:
                    if message["role"] == "system":
                        prompt += f"System: {message['content']}\n\n"
                    elif message["role"] == "user":
                        prompt += f"Human: {message['content']}\n\n"
                    elif message["role"] == "assistant":
                        prompt += f"Assistant: {message['content']}\n\n"

                prompt += "Assistant:"

                # Generate response
                inputs = self.tokenizer(prompt, return_tensors="pt")
                with torch.no_grad():
                    outputs = self.model.generate(
                        **inputs,
                        max_new_tokens=max_tokens,
                        do_sample=temperature > 0,
                        temperature=temperature if temperature > 0 else 1.0,
                        pad_token_id=self.tokenizer.eos_token_id
                    )

                # Decode only the generated part
                generated_text = self.tokenizer.decode(
                    outputs[0][inputs['input_ids'].shape[1]:],
                    skip_special_tokens=True
                ).strip()

                return jsonify({
                    "choices": [{
                        "message": {
                            "role": "assistant",
                            "content": generated_text
                        }
                    }]
                })

            except Exception as e:
                logger.error(f"Chat error: {e}")
                return jsonify({"error": str(e)}), 500

    def load_model(self):
        """Load the model and tokenizer"""
        try:
            logger.info(f"Loading model: {self.model_name}")

            # Load tokenizer
            self.tokenizer = AutoTokenizer.from_pretrained(self.model_name)

            # Set pad token if not present
            if self.tokenizer.pad_token is None:
                self.tokenizer.pad_token = self.tokenizer.eos_token

            # Load model
            self.model = AutoModelForCausalLM.from_pretrained(self.model_name)

            self.model_loaded = True
            logger.info("Model loaded successfully!")
            logger.info(f"Model parameters: {sum(p.numel() for p in self.model.parameters()):,}")

            return True

        except Exception as e:
            logger.error(f"Failed to load model: {e}")
            return False

    def run(self):
        """Start the server"""
        logger.info(f"Starting simple test server on {self.host}:{self.port}")
        logger.info(f"Using model: {self.model_name}")

        # Load model
        if self.load_model():
            logger.info("Model loaded successfully, starting server...")
        else:
            logger.error("Failed to load model, exiting...")
            return False

        try:
            self.app.run(host=self.host, port=self.port, debug=False)
            return True
        except Exception as e:
            logger.error(f"Server error: {e}")
            return False

def main():
    """Main entry point"""
    import argparse

    parser = argparse.ArgumentParser(description="Simple Test Server for Hugging Face")
    parser.add_argument("--model", default="hf-internal-testing/tiny-random-gpt2",
                       help="Model name to load")
    parser.add_argument("--host", default="127.0.0.1", help="Host to bind to")
    parser.add_argument("--port", type=int, default=8899, help="Port to bind to")

    args = parser.parse_args()

    server = SimpleTestServer(
        model_name=args.model,
        host=args.host,
        port=args.port
    )

    try:
        server.run()
    except KeyboardInterrupt:
        logger.info("Server stopped by user")
        return 0
    except Exception as e:
        logger.error(f"Server error: {e}")
        return 1

    return 0

if __name__ == "__main__":
    exit(main())
