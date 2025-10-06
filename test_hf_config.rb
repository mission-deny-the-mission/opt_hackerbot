#!/usr/bin/env ruby
"""
Quick test to verify Hugging Face configuration is working
"""

require_relative 'providers/llm_client_factory'
require_relative 'bot_manager'
require_relative 'print.rb'

def test_hf_configuration
  puts "🧪 Testing Hugging Face Configuration"
  puts "====================================="

  # Test 1: Direct LLM Client Creation
  puts "\n1. Testing direct LLM client creation..."
  begin
    client = LLMClientFactory.create_client('huggingface',
      host: '127.0.0.1',
      port: 8899,
      model: 'EleutherAI/gpt-neo-125m',
      max_tokens: 20,
      temperature: 0.7,
      streaming: false,
      timeout: 30
    )

    puts "   ✅ LLM client created successfully"
    puts "   Provider: #{client.provider}"
    puts "   Model: #{client.model}"
    puts "   Host: #{client.instance_variable_get(:@host)}"
    puts "   Port: #{client.instance_variable_get(:@port)}"

  rescue => e
    puts "   ❌ LLM client creation failed: #{e.message}"
    return false
  end

  # Test 2: BotManager Configuration Parsing
  puts "\n2. Testing BotManager configuration parsing..."
  begin
    # Create a BotManager with Hugging Face parameters
    bot_manager = BotManager.new(
      'localhost',  # irc_server_ip_address
      'huggingface',  # llm_provider
      'localhost', 11434, 'gemma3:1b',  # ollama params (ignored)
      nil, nil,  # openai params (ignored)
      'localhost', 8000,  # vllm params (ignored)
      'localhost', 30000,  # sglang params (ignored)
      '127.0.0.1', 8899, 'EleutherAI/gpt-neo-125m', 300,  # hf params
      false,  # enable_rag_cag
      {}  # rag_cag_config
    )

    puts "   ✅ BotManager created with Hugging Face parameters"

    # Test reading the bot configuration
    bots = bot_manager.read_bots

    if bots.empty?
      puts "   ⚠️  No bot configurations found"
    else
      puts "   ✅ Found #{bots.length} bot configuration(s)"

      bots.each do |bot_name, bot_config|
        puts "   Bot: #{bot_name}"
        if bot_config['chat_ai']
          ai_client = bot_config['chat_ai']
          puts "     Provider: #{ai_client.provider}"
          puts "     Model: #{ai_client.model}"

          if ai_client.provider == 'huggingface'
            puts "     ✅ Bot is using Hugging Face client!"

            # Test connection to HF server
            puts "     Testing connection..."
            if ai_client.test_connection
              puts "     ✅ Connection test passed"

              # Test generation
              puts "     Testing generation..."
              response = ai_client.generate_response("Hello, AI!")
              if response
                puts "     ✅ Generation successful: #{response[0..50]}..."
              else
                puts "     ❌ Generation failed"
              end
            else
              puts "     ❌ Connection test failed (is HF server running?)"
            end
          else
            puts "     ❌ Bot is using wrong provider: #{ai_client.provider}"
          end
        else
          puts "     ❌ No AI client configured"
        end
      end
    end

  rescue => e
    puts "   ❌ BotManager test failed: #{e.message}"
    puts "   #{e.backtrace.first(5).join("\n   ")}"
    return false
  end

  puts "\n✅ Configuration test completed!"
  return true
end

# Run the test
if __FILE__ == $0
  success = test_hf_configuration()
  exit(success ? 0 : 1)
end
