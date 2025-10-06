#!/usr/bin/env ruby
"""
Demo script for Hugging Face Llama 3.2 integration with Hackerbot
This script demonstrates the Hugging Face client functionality
"""

require_relative 'providers/llm_client_factory'
require_relative 'print.rb'

def test_hf_connection
  puts "🔗 Testing Hugging Face server connection..."

  begin
    client = LLMClientFactory.create_client('huggingface',
      host: '127.0.0.1',
      port: 8899,
      model: 'TinyLlama/TinyLlama-1.1B-Chat-v1.0',
      streaming: false,
      timeout: 60
    )

    if client.test_connection
      puts "✅ Hugging Face server is connected and ready!"

      # Get model info
      model_info = client.get_model_info
      if model_info
        puts "📋 Model Info:"
        puts "   Current Model: #{model_info['current_model']}"
        puts "   Loaded: #{model_info['loaded'] ? 'Yes' : 'No'}"
        puts "   Device: #{model_info['device']}"
      end

      return true
    else
      puts "❌ Failed to connect to Hugging Face server"
      puts "   Make sure the server is running with: make start-hf"
      return false
    end
  rescue => e
    puts "❌ Error testing Hugging Face connection: #{e.message}"
    return false
  end
end

def test_basic_generation
  puts "\n🤖 Testing basic text generation..."

  begin
    client = LLMClientFactory.create_client('huggingface',
      host: '127.0.0.1',
      port: 8899,
      model: 'TinyLlama/TinyLlama-1.1B-Chat-v1.0',
      max_tokens: 100,
      temperature: 0.7,
      streaming: false
    )

    prompt = "Explain what a firewall is in cybersecurity in simple terms."
    puts "📝 Prompt: #{prompt}"
    puts "⏳ Generating response..."

    start_time = Time.now
    response = client.generate_response(prompt)
    end_time = Time.now

    if response
      puts "✅ Response generated successfully!"
      puts "⏱️  Generation time: #{(end_time - start_time).round(2)} seconds"
      puts "📄 Response:"
      puts "   #{response}"
    else
      puts "❌ Failed to generate response"
    end

  rescue => e
    puts "❌ Error during basic generation: #{e.message}"
  end
end

def test_streaming_generation
  puts "\n🌊 Testing streaming text generation..."

  begin
    client = LLMClientFactory.create_client('huggingface',
      host: '127.0.0.1',
      port: 8899,
      model: 'TinyLlama/TinyLlama-1.1B-Chat-v1.0',
      max_tokens: 150,
      temperature: 0.8,
      streaming: true
    )

    prompt = "List 3 common network security best practices."
    puts "📝 Prompt: #{prompt}"
    puts "⏳ Streaming response:"
    puts "   "

    full_response = ""
    start_time = Time.now

    # Define callback for streaming
    stream_callback = lambda do |chunk|
      print chunk
      STDOUT.flush
      full_response += chunk
    end

    response = client.generate_response(prompt, stream_callback)
    end_time = Time.now

    puts "\n"
    puts "✅ Streaming completed!"
    puts "⏱️  Generation time: #{(end_time - start_time).round(2)} seconds"
    puts "📊 Total characters: #{full_response.length}"

  rescue => e
    puts "❌ Error during streaming generation: #{e.message}"
  end
end

def test_cybersecurity_knowledge
  puts "\n🛡️  Testing cybersecurity knowledge..."

  cybersecurity_prompts = [
    "What is the difference between a vulnerability and an exploit?",
    "Explain the concept of defense in depth.",
    "What is social engineering and how can it be prevented?"
  ]

  begin
    client = LLMClientFactory.create_client('huggingface',
      host: '127.0.0.1',
      port: 8899,
      model: 'TinyLlama/TinyLlama-1.1B-Chat-v1.0',
      max_tokens: 120,
      temperature: 0.6,
      streaming: false,
      system_prompt: "You are a cybersecurity expert providing educational explanations. Be clear, concise, and practical."
    )

    cybersecurity_prompts.each_with_index do |prompt, index|
      puts "\n#{index + 1}. 📝 Prompt: #{prompt}"
      puts "   ⏳ Generating response..."

      start_time = Time.now
      response = client.generate_response(prompt)
      end_time = Time.now

      if response
        puts "   ✅ Response (#{(end_time - start_time).round(2)}s):"
        puts "   #{response.lines.first.strip}..."
      else
        puts "   ❌ Failed to generate response"
      end
    end

  rescue => e
    puts "❌ Error during cybersecurity knowledge test: #{e.message}"
  end
end

def test_performance
  puts "\n⚡ Testing performance with different settings..."

  test_configs = [
    { name: "Fast (low tokens)", max_tokens: 50, temperature: 0.3 },
    { name: "Balanced", max_tokens: 100, temperature: 0.7 },
    { name: "Creative (high temp)", max_tokens: 80, temperature: 1.0 }
  ]

  test_prompt = "What is penetration testing?"

  test_configs.each do |config|
    puts "\n🧪 Testing #{config[:name]} configuration..."

    begin
      client = LLMClientFactory.create_client('huggingface',
        host: '127.0.0.1',
        port: 8899,
        model: 'TinyLlama/TinyLlama-1.1B-Chat-v1.0',
        max_tokens: config[:max_tokens],
        temperature: config[:temperature],
        streaming: false
      )

      start_time = Time.now
      response = client.generate_response(test_prompt)
      end_time = Time.now

      if response
        duration = (end_time - start_time).round(2)
        puts "   ✅ Completed in #{duration}s"
        puts "   📊 Tokens: #{config[:max_tokens]}, Temperature: #{config[:temperature]}"
        puts "   📄 Response preview: #{response[0..100]}..."
      else
        puts "   ❌ Failed to generate response"
      end

    rescue => e
      puts "   ❌ Error: #{e.message}"
    end
  end
end

def main
  puts "🚀 Hugging Face Llama 3.2 Integration Demo"
  puts "=========================================="
  puts ""

  # Test connection first
  unless test_hf_connection
    puts "\n❌ Cannot proceed without Hugging Face server connection"
    puts "   Please start the server with: make start-hf"
    exit 1
  end

  # Run tests
  test_basic_generation
  test_streaming_generation
  test_cybersecurity_knowledge
  test_performance

  puts "\n🎉 Demo completed!"
  puts ""
  puts "📋 Summary:"
  puts "   • Hugging Face server provides local TinyLlama inference"
  puts "   • Supports both streaming and non-streaming responses"
  puts "   • Configurable temperature and token limits"
  puts "   • Integrated with Hackerbot's LLM client system"
  puts ""
  puts "🔧 Usage in Hackerbot:"
  puts "   make start-hf    # Start Hugging Face server"
  puts "   make bot-hf      # Start Hackerbot with Hugging Face"
  puts "   make bot-hf-rag-cag  # Start with RAG + CAG enabled"
end

# Run the demo
if __FILE__ == $0
  main
end
