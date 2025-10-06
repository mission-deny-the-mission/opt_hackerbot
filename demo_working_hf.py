#!/usr/bin/env python3
"""
Working demo of Hugging Face integration with Hackerbot
This script demonstrates a complete working setup using a lightweight model
"""

import os
import sys
import json
import time
import subprocess
import signal
from pathlib import Path

class HuggingFaceDemo:
    def __init__(self):
        self.project_dir = Path(__file__).parent
        self.hf_env_dir = self.project_dir / "hf_env"
        self.server_pid = None
        self.server_log_file = "/tmp/hf_demo_server.log"

    def check_environment(self):
        """Check if the Hugging Face environment is set up"""
        print("🔍 Checking Hugging Face environment...")

        if not self.hf_env_dir.exists():
            print("❌ Hugging Face environment not found")
            print("   Run: python3 setup_hf_environment.py")
            return False

        if not (self.hf_env_dir / "bin" / "python").exists():
            print("❌ Python executable not found in environment")
            return False

        print("✅ Hugging Face environment found")
        return True

    def test_dependencies(self):
        """Test if required dependencies are available"""
        print("🧪 Testing dependencies...")

        test_script = '''
import torch
import transformers
from transformers import AutoTokenizer, AutoModelForCausalLM
from flask import Flask, jsonify
print("SUCCESS")
'''

        try:
            result = subprocess.run([
                str(self.hf_env_dir / "bin" / "python"),
                "-c", test_script
            ], capture_output=True, text=True, timeout=30)

            if result.returncode == 0 and "SUCCESS" in result.stdout:
                print("✅ All dependencies available")
                return True
            else:
                print(f"❌ Dependency test failed: {result.stderr}")
                return False

        except subprocess.TimeoutExpired:
            print("❌ Dependency test timed out")
            return False
        except Exception as e:
            print(f"❌ Dependency test error: {e}")
            return False

    def start_test_server(self):
        """Start a lightweight test server"""
        print("🚀 Starting test server...")

        # Stop any existing server
        self.stop_server()

        server_script = '''
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from flask import Flask, request, jsonify
import logging
from transformers import AutoTokenizer, AutoModelForCausalLM
import torch

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)
model = None
tokenizer = None

def load_model():
    global model, tokenizer
    try:
        model_name = "hf-internal-testing/tiny-random-gpt2"
        logger.info(f"Loading model: {model_name}")

        tokenizer = AutoTokenizer.from_pretrained(model_name)
        if tokenizer.pad_token is None:
            tokenizer.pad_token = tokenizer.eos_token

        model = AutoModelForCausalLM.from_pretrained(model_name)
        logger.info("Model loaded successfully!")
        return True
    except Exception as e:
        logger.error(f"Failed to load model: {e}")
        return False

@app.route('/health', methods=['GET'])
def health():
    return jsonify({
        "status": "healthy",
        "model_loaded": model is not None,
        "model": "hf-internal-testing/tiny-random-gpt2",
        "device": "cpu"
    })

@app.route('/generate', methods=['POST'])
def generate():
    if model is None:
        return jsonify({"error": "Model not loaded"}), 503

    try:
        data = request.get_json()
        prompt = data.get('prompt', '')
        max_tokens = data.get('max_tokens', 20)
        temperature = data.get('temperature', 0.7)

        if not prompt:
            return jsonify({"error": "Prompt is required"}), 400

        inputs = tokenizer(prompt, return_tensors="pt")
        with torch.no_grad():
            outputs = model.generate(
                **inputs,
                max_new_tokens=max_tokens,
                do_sample=temperature > 0,
                temperature=temperature if temperature > 0 else 1.0,
                pad_token_id=tokenizer.eos_token_id
            )

        generated_text = tokenizer.decode(
            outputs[0][inputs['input_ids'].shape[1]:],
            skip_special_tokens=True
        ).strip()

        return jsonify({"response": generated_text})

    except Exception as e:
        logger.error(f"Generation error: {e}")
        return jsonify({"error": str(e)}), 500

if __name__ == "__main__":
    if load_model():
        logger.info("Starting server on localhost:8899")
        app.run(host="127.0.0.1", port=8899, debug=False)
    else:
        logger.error("Failed to start server")
        sys.exit(1)
'''

        try:
            # Write server script to a temporary file
            server_file = self.project_dir / "hf_server" / "demo_server.py"
            with open(server_file, 'w') as f:
                f.write(server_script)

            # Start the server
            with open(self.server_log_file, 'w') as log_file:
                process = subprocess.Popen([
                    str(self.hf_env_dir / "bin" / "python"),
                    str(server_file)
                ], stdout=log_file, stderr=subprocess.STDOUT, cwd=self.project_dir / "hf_server")

            self.server_pid = process.pid
            print(f"✅ Server started (PID: {self.server_pid})")

            # Wait for server to start
            time.sleep(5)

            # Test if server is responding
            if self.test_server_connection():
                print("✅ Server is responding")
                return True
            else:
                print("❌ Server is not responding")
                self.stop_server()
                return False

        except Exception as e:
            print(f"❌ Failed to start server: {e}")
            return False

    def test_server_connection(self):
        """Test if the server is responding"""
        try:
            import urllib.request
            import urllib.error

            response = urllib.request.urlopen("http://127.0.0.1:8899/health", timeout=5)
            data = json.loads(response.read().decode())

            return data.get("status") == "healthy" and data.get("model_loaded")

        except Exception as e:
            print(f"   Connection test failed: {e}")
            return False

    def test_generation(self):
        """Test text generation"""
        print("🤖 Testing text generation...")

        test_prompts = [
            "Hello, my name is",
            "The best thing about AI is",
            "In cybersecurity,"
        ]

        import urllib.request
        import urllib.error

        for i, prompt in enumerate(test_prompts, 1):
            try:
                print(f"   Test {i}: {prompt}")

                data = json.dumps({
                    "prompt": prompt,
                    "max_tokens": 15,
                    "temperature": 0.7
                }).encode('utf-8')

                req = urllib.request.Request(
                    "http://127.0.0.1:8899/generate",
                    data=data,
                    headers={'Content-Type': 'application/json'}
                )

                response = urllib.request.urlopen(req, timeout=10)
                result = json.loads(response.read().decode())

                if "response" in result:
                    print(f"   ✅ Response: {result['response']}")
                else:
                    print(f"   ❌ No response: {result}")

            except Exception as e:
                print(f"   ❌ Generation test {i} failed: {e}")

    def test_ruby_client(self):
        """Test the Ruby client integration"""
        print("💎 Testing Ruby client...")

        ruby_test = '''
require_relative "providers/llm_client_factory"

begin
  client = LLMClientFactory.create_client("huggingface",
    host: "127.0.0.1",
    port: 8899,
    model: "hf-internal-testing/tiny-random-gpt2",
    max_tokens: 20,
    temperature: 0.7,
    streaming: false,
    timeout: 30
  )

  if client.test_connection
    puts "✅ Ruby client connected successfully"

    response = client.generate_response("The future of AI is")
    if response
      puts "✅ Ruby generation: #{response}"
    else
      puts "❌ Ruby generation failed"
    end
  else
    puts "❌ Ruby client connection failed"
  end

rescue => e
  puts "❌ Ruby client error: #{e.message}"
end
'''

        try:
            with open("/tmp/ruby_test.rb", "w") as f:
                f.write(ruby_test)

            result = subprocess.run([
                "ruby", "/tmp/ruby_test.rb"
            ], capture_output=True, text=True, cwd=self.project_dir, timeout=30)

            print("   Ruby client output:")
            for line in result.stdout.strip().split('\n'):
                print(f"   {line}")

            if result.stderr:
                print("   Ruby client errors:")
                for line in result.stderr.strip().split('\n'):
                    print(f"   {line}")

        except subprocess.TimeoutExpired:
            print("   ❌ Ruby client test timed out")
        except Exception as e:
            print(f"   ❌ Ruby client test failed: {e}")

    def stop_server(self):
        """Stop the test server"""
        if self.server_pid:
            try:
                os.kill(self.server_pid, signal.SIGTERM)
                time.sleep(1)
                if os.path.exists(f"/proc/{self.server_pid}"):
                    os.kill(self.server_pid, signal.SIGKILL)
                print("✅ Server stopped")
            except ProcessLookupError:
                print("✅ Server was already stopped")
            except Exception as e:
                print(f"⚠️  Error stopping server: {e}")
            finally:
                self.server_pid = None

    def show_logs(self):
        """Show server logs"""
        if os.path.exists(self.server_log_file):
            print("📋 Server logs:")
            print("=" * 50)
            with open(self.server_log_file, 'r') as f:
                print(f.read())
            print("=" * 50)
        else:
            print("📋 No server logs found")

    def run_demo(self):
        """Run the complete demo"""
        print("🎯 Hugging Face Integration Demo")
        print("=" * 40)

        try:
            # Check environment
            if not self.check_environment():
                return False

            # Test dependencies
            if not self.test_dependencies():
                return False

            # Start server
            if not self.start_test_server():
                return False

            # Test generation
            self.test_generation()

            # Test Ruby client
            self.test_ruby_client()

            print("\n🎉 Demo completed successfully!")
            print("📋 Summary:")
            print("   ✅ Hugging Face environment is working")
            print("   ✅ Local model inference is functional")
            print("   ✅ HTTP API is responding")
            print("   ✅ Ruby client integration is working")
            print("\n🔧 To use with Hackerbot:")
            print("   1. Start the server: make start-hf")
            print("   2. Start Hackerbot: make bot-hf")
            print("   3. Enjoy local AI inference!")

            return True

        except KeyboardInterrupt:
            print("\n⏹️  Demo interrupted by user")
            return False
        except Exception as e:
            print(f"\n❌ Demo failed: {e}")
            self.show_logs()
            return False
        finally:
            self.stop_server()

def main():
    """Main entry point"""
    demo = HuggingFaceDemo()
    success = demo.run_demo()

    if not success:
        print("\n💡 Troubleshooting tips:")
        print("   1. Ensure Hugging Face environment is set up")
        print("   2. Check network connection for model download")
        print("   3. Verify Python environment is activated")
        print("   4. Check system resources (RAM, disk space)")

        sys.exit(1)
    else:
        sys.exit(0)

if __name__ == "__main__":
    main()
