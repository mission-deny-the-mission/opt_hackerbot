#!/usr/bin/env python3
"""
Setup script for Hugging Face environment
This script creates a virtual environment and installs the required dependencies
to avoid Nix build issues with complex ML packages.
"""

import os
import sys
import subprocess
import venv
from pathlib import Path

def run_command(cmd, cwd=None, capture_output=True):
    """Run a command and return the result"""
    try:
        result = subprocess.run(
            cmd,
            shell=True,
            cwd=cwd,
            capture_output=capture_output,
            text=True,
            check=True
        )
        return True, result.stdout.strip()
    except subprocess.CalledProcessError as e:
        return False, e.stderr.strip()

def check_python_version():
    """Check if Python version is compatible"""
    version = sys.version_info
    if version.major < 3 or (version.major == 3 and version.minor < 8):
        print("❌ Python 3.8 or higher is required")
        return False

    print(f"✅ Python {version.major}.{version.minor}.{version.micro} detected")
    return True

def create_virtual_environment():
    """Create virtual environment for Hugging Face"""
    venv_path = Path("hf_env")

    if venv_path.exists():
        print("✅ Virtual environment already exists")
        return True

    print("📦 Creating virtual environment...")
    try:
        venv.create(venv_path, with_pip=True)
        print("✅ Virtual environment created successfully")
        return True
    except Exception as e:
        print(f"❌ Failed to create virtual environment: {e}")
        return False

def get_venv_python():
    """Get path to virtual environment Python"""
    if sys.platform == "win32":
        return Path("hf_env/Scripts/python.exe")
    else:
        return Path("hf_env/bin/python")

def get_venv_pip():
    """Get path to virtual environment pip"""
    if sys.platform == "win32":
        return Path("hf_env/Scripts/pip.exe")
    else:
        return Path("hf_env/bin/pip")

def install_dependencies():
    """Install required dependencies"""
    pip_path = get_venv_pip()

    if not pip_path.exists():
        print("❌ Virtual environment pip not found")
        return False

    print("📦 Installing Hugging Face dependencies...")

    # Basic dependencies that should work
    packages = [
        "torch",
        "transformers",
        "accelerate",
        "sentencepiece",
        "tokenizers",
        "flask",
        "flask-cors"
    ]

    for package in packages:
        print(f"   Installing {package}...")
        success, output = run_command(f"{pip_path} install {package}")

        if not success:
            print(f"   ⚠️  Failed to install {package}: {output}")
            print(f"   Trying alternative installation method...")
            # Try with --no-cache-dir flag
            success, output = run_command(f"{pip_path} install --no-cache-dir {package}")
            if not success:
                print(f"   ❌ Still failed to install {package}")
                return False
            else:
                print(f"   ✅ {package} installed (alternative method)")
        else:
            print(f"   ✅ {package} installed")

    print("✅ All dependencies installed successfully")
    return True

def test_imports():
    """Test if all required packages can be imported"""
    python_path = get_venv_python()

    # Test imports directly
    try:
        import subprocess
        result = subprocess.run(
            [str(get_venv_python()), "-c",
             "import torch, transformers, flask, flask_cors; print('SUCCESS')"],
            capture_output=True,
            text=True
        )

        if result.returncode == 0 and "SUCCESS" in result.stdout:
            print("✅ All packages can be imported successfully")
            return True
        else:
            print(f"❌ Import test failed: {result.stderr}")
            return False
    except Exception as e:
        print(f"❌ Import test failed: {e}")
        return False



def create_activation_script():
    """Create activation script for convenience"""
    if sys.platform == "win32":
        script_content = """@echo off
echo Activating Hugging Face environment...
call hf_env\\Scripts\\activate.bat
echo Environment activated. Python is now: %PYTHONPATH%
echo To deactivate, type: deactivate
"""
        script_path = "activate_hf.bat"
    else:
        script_content = """#!/bin/bash
echo "Activating Hugging Face environment..."
source hf_env/bin/activate
echo "Environment activated. Python is now: $(which python)"
echo "To deactivate, type: deactivate"
"""
        script_path = "activate_hf.sh"

    try:
        with open(script_path, 'w') as f:
            f.write(script_content)

        # Make executable on Unix systems
        if sys.platform != "win32":
            os.chmod(script_path, 0o755)

        print(f"✅ Created activation script: {script_path}")
        return True
    except Exception as e:
        print(f"❌ Failed to create activation script: {e}")
        return False

def create_requirements_file():
    """Create requirements.txt file"""
    requirements = """torch
transformers
accelerate
sentencepiece
tokenizers
flask
flask-cors
"""

    try:
        with open("requirements.txt", 'w') as f:
            f.write(requirements)
        print("✅ Created requirements.txt file")
        return True
    except Exception as e:
        print(f"❌ Failed to create requirements.txt: {e}")
        return False

def main():
    """Main setup function"""
    print("🤖 Hugging Face Environment Setup")
    print("=================================")
    print()

    # Check Python version
    if not check_python_version():
        return 1

    # Create virtual environment
    if not create_virtual_environment():
        return 1

    # Install dependencies
    if not install_dependencies():
        print("❌ Failed to install dependencies")
        print()
        print("Troubleshooting tips:")
        print("1. Check your internet connection")
        print("2. Try running: python3 -m pip install --upgrade pip")
        print("3. If using a corporate network, check proxy settings")
        print("4. Try installing packages individually")
        return 1

    # Test imports
    if not test_imports():
        print("❌ Import test failed")
        return 1

    # Create convenience files
    create_activation_script()
    create_requirements_file()

    print()
    print("🎉 Setup completed successfully!")
    print()
    print("📋 Next steps:")
    print(f"1. Activate environment: {'source activate_hf.sh' if sys.platform != 'win32' else 'activate_hf.bat'}")
    print("2. Start the server: cd hf_server && python hf_inference_server.py")
    print("3. Test with: make bot-hf")
    print()
    print("🔧 Or use the convenience aliases:")
    print("- make setup-hf    # Setup environment")
    print("- make start-hf    # Start Hugging Face server")
    print()
    print("📁 Files created:")
    print("- hf_env/          # Virtual environment")
    print("- activate_hf.sh   # Activation script")
    print("- requirements.txt # Dependencies list")

    return 0

if __name__ == "__main__":
    exit(main())
