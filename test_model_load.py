#!/usr/bin/env python3
"""
Simple test to check if we can load a model
"""

import sys
import os

# Add the virtual environment to the path
sys.path.insert(0, './hf_env/lib/python3.11/site-packages')

def test_basic_imports():
    """Test basic imports"""
    try:
        print("Testing basic imports...")
        import torch
        import transformers
        from transformers import AutoTokenizer, AutoModelForCausalLM
        print("✅ All imports successful")
        return True
    except Exception as e:
        print(f"❌ Import failed: {e}")
        return False

def test_small_model():
    """Test loading a very small model"""
    try:
        print("\nTesting small model loading...")

        # Use a tiny model that should load quickly
        model_name = "hf-internal-testing/tiny-random-gpt2"

        print(f"Loading model: {model_name}")

        # Load tokenizer
        tokenizer = AutoTokenizer.from_pretrained(model_name)
        print("✅ Tokenizer loaded")

        # Load model
        model = AutoModelForCausalLM.from_pretrained(model_name)
        print("✅ Model loaded")

        # Test generation
        inputs = tokenizer("Hello, world!", return_tensors="pt")
        outputs = model.generate(**inputs, max_new_tokens=5)
        result = tokenizer.decode(outputs[0], skip_special_tokens=True)
        print(f"✅ Generation test successful: {result}")

        return True

    except Exception as e:
        print(f"❌ Model loading failed: {e}")
        return False

def test_simple_server():
    """Test a simple Flask server"""
    try:
        print("\nTesting simple Flask server...")
        from flask import Flask, jsonify

        app = Flask(__name__)

        @app.route('/test')
        def test():
            return jsonify({"status": "ok", "message": "Server is working"})

        print("✅ Flask app created successfully")
        return True

    except Exception as e:
        print(f"❌ Flask test failed: {e}")
        return False

def main():
    print("🧪 Hugging Face Environment Test")
    print("===============================")

    # Change to the project directory if needed
    os.chdir(os.path.dirname(os.path.abspath(__file__)))

    # Activate virtual environment and test
    import subprocess

    try:
        # Run tests in the virtual environment
        result = subprocess.run([
            './hf_env/bin/python', '-c', '''
import sys
sys.path.insert(0, "./hf_env/lib/python3.11/site-packages")

try:
    import torch
    import transformers
    from transformers import AutoTokenizer, AutoModelForCausalLM
    from flask import Flask, jsonify

    print("✅ All dependencies imported successfully")

    # Test with a tiny model
    model_name = "hf-internal-testing/tiny-random-gpt2"
    print(f"Loading tiny model: {model_name}")

    tokenizer = AutoTokenizer.from_pretrained(model_name)
    model = AutoModelForCausalLM.from_pretrained(model_name)

    print("✅ Tiny model loaded successfully")
    print("✅ Environment is ready for Hugging Face inference")

except Exception as e:
    print(f"❌ Error: {e}")
    sys.exit(1)
'''
        ], capture_output=True, text=True)

        if result.returncode == 0:
            print(result.stdout)
            return True
        else:
            print(f"❌ Test failed: {result.stderr}")
            return False

    except Exception as e:
        print(f"❌ Test execution failed: {e}")
        return False

if __name__ == "__main__":
    success = main()
    if success:
        print("\n🎉 All tests passed!")
    else:
        print("\n❌ Some tests failed!")
        sys.exit(1)
