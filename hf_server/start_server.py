#!/usr/bin/env python3
"""
Startup script for Hugging Face inference server
Handles model download and server initialization
"""

import os
import sys
import subprocess
import time
import signal
import argparse
from pathlib import Path

def check_dependencies():
    """Check if required dependencies are available"""
    try:
        import torch
        import transformers
        import flask
        import flask_cors
        print("✅ All required dependencies are available")
        return True
    except ImportError as e:
        print(f"❌ Missing dependency: {e}")
        print("   Make sure you're in the Nix development environment")
        return False

def check_model_availability(model_name, cache_dir):
    """Check if model is already downloaded"""
    from transformers import AutoTokenizer

    try:
        cache_path = Path(cache_dir) / "--files--" / model_name.replace("/", "--")
        if cache_path.exists():
            print(f"✅ Model {model_name} is already cached")
            return True
        else:
            print(f"📥 Model {model_name} needs to be downloaded")
            return False
    except Exception:
        return False

def download_model(model_name, cache_dir):
    """Download the model if not already available"""
    from transformers import AutoTokenizer, AutoModelForCausalLM

    print(f"📥 Downloading model: {model_name}")
    print("   This may take a while depending on your internet connection...")

    try:
        # Create cache directory
        os.makedirs(cache_dir, exist_ok=True)

        # Download tokenizer first
        print("   Downloading tokenizer...")
        tokenizer = AutoTokenizer.from_pretrained(
            model_name,
            cache_dir=cache_dir,
            trust_remote_code=True
        )

        # Download model
        print("   Downloading model weights...")
        model = AutoModelForCausalLM.from_pretrained(
            model_name,
            cache_dir=cache_dir,
            torch_dtype="auto",
            trust_remote_code=True
        )

        print("✅ Model download completed successfully!")
        return True

    except Exception as e:
        print(f"❌ Failed to download model: {e}")
        return False

def start_server(model_name, host, port, device, no_download):
    """Start the inference server"""
    # Import here to avoid import errors if dependencies are missing
    from hf_inference_server import HuggingFaceInferenceServer

    print(f"🚀 Starting Hugging Face inference server...")
    print(f"   Model: {model_name}")
    print(f"   Host: {host}")
    print(f"   Port: {port}")
    print(f"   Device: {device}")

    # Create and configure server
    server = HuggingFaceInferenceServer(
        model_name=model_name,
        host=host,
        port=port,
        device=device
    )

    # Handle graceful shutdown
    def signal_handler(signum, frame):
        print("\n🛑 Received shutdown signal, stopping server...")
        sys.exit(0)

    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)

    try:
        server.run(load_model_on_startup=True)
    except KeyboardInterrupt:
        print("\n🛑 Server stopped by user")
    except Exception as e:
        print(f"❌ Server error: {e}")
        return 1

    return 0

def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(description="Hugging Face Server Startup Script")
    parser.add_argument("--model", default="EleutherAI/gpt-neo-125m",
                       help="Model name to use")
    parser.add_argument("--host", default="127.0.0.1", help="Host to bind to")
    parser.add_argument("--port", type=int, default=8899, help="Port to bind to")
    parser.add_argument("--device", default="auto",
                       choices=["auto", "cpu", "cuda", "mps"],
                       help="Device to use for inference")
    parser.add_argument("--cache-dir", default="./models",
                       help="Directory to cache models")
    parser.add_argument("--no-download", action="store_true",
                       help="Skip model download check")
    parser.add_argument("--download-only", action="store_true",
                       help="Only download the model, don't start server")

    args = parser.parse_args()

    print("🤖 Hugging Face Inference Server Startup")
    print("=======================================")

    # Check dependencies
    if not check_dependencies():
        return 1

    # Check model availability and download if needed
    if not args.no_download:
        if not check_model_availability(args.model, args.cache_dir):
            if not download_model(args.model, args.cache_dir):
                return 1
        else:
            print("✅ Model is available, proceeding...")

    # Stop here if only downloading
    if args.download_only:
        print("📦 Model download completed!")
        return 0

    # Start the server
    return start_server(args.model, args.host, args.port, args.device, args.no_download)

if __name__ == "__main__":
    exit(main())
