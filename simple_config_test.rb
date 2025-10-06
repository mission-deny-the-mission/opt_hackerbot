#!/usr/bin/env ruby
"""
Simple test to verify Hugging Face configuration is working
"""

require_relative 'providers/llm_client_factory'
require_relative 'bot_manager'
require_relative 'print.rb'

def test_hf_configuration_parsing
  puts "🧪 Testing Hugging Face Configuration Parsing"
  puts "============================================="

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

    puts "✅ BotManager created with Hugging Face parameters"

    # Test reading the bot configuration
    bots = bot_manager.read_bots

    if bots.empty?
      puts "⚠️  No bot configurations found"
      return false
    else
      puts "✅ Found #{bots.length} bot configuration(s)"

      bots.each do |bot_name, bot_config|
        puts "Bot: #{bot_name}"
        if bot_config['chat_ai']
          ai_client = bot_config['chat_ai']
          puts "  Provider: #{ai_client.provider}"
          puts "  Model: #{ai_client.model}"
          puts "  Host: #{ai_client.instance_variable_get(:@host)}"
          puts "  Port: #{ai_client.instance_variable_get(:@port)}"

          if ai_client.provider == 'huggingface'
            puts "✅ SUCCESS: Bot is using Hugging Face client!"

            # Verify configuration values
            hf_host = ai_client.instance_variable_get(:@host)
            hf_port = ai_client.instance_variable_get(:@port)
            hf_model = ai_client.model

            expected_host = '127.0.0.1'
            expected_port = 8899
            expected_model = 'EleutherAI/gpt-neo-125m'

            if hf_host == expected_host && hf_port == expected_port && hf_model == expected_model
              puts "✅ All configuration values are correct!"
              puts "  Host: #{hf_host} (expected: #{expected_host})"
              puts "  Port: #{hf_port} (expected: #{expected_port})"
              puts "  Model: #{hf_model} (expected: #{expected_model})"
              return true
            else
              puts "❌ Configuration values mismatch:"
              puts "  Host: #{hf_host} (expected: #{expected_host})"
              puts "  Port: #{hf_port} (expected: #{expected_port})"
              puts "  Model: #{hf_model} (expected: #{expected_model})"
              return false
            end
          else
            puts "❌ Bot is using wrong provider: #{ai_client.provider}"
            return false
          end
        else
          puts "❌ No AI client configured"
          return false
        end
      end
    end

  rescue => e
    puts "❌ BotManager test failed: #{e.message}"
    puts e.backtrace.first(5).join("\n")
    return false
  end
end

# Run the test
if __FILE__ == $0
  puts "🎯 Hugging Face Configuration Test"
  puts "==================================="
  puts "This test verifies that the Hugging Face configuration is working correctly"
  puts ""

  success = test_hf_configuration_parsing()

  if success
    puts "\n🎉 CONFIGURATION TEST PASSED!"
    puts "============================="
    puts "✅ Hugging Face configuration parsing: WORKING"
    puts "✅ BotManager integration: WORKING"
    puts "✅ XML configuration reading: WORKING"
    puts "✅ LLM client creation: WORKING"
    puts ""
    puts "🔧 ISSUE RESOLVED:"
    puts "The bot was trying to use Ollama because config/bot_o.xml had hardcoded"
    puts "<llm_provider>ollama</llm_provider>. This has been FIXED!"
    puts ""
    puts "🚀 TO USE:"
    puts "1. Start Hugging Face server: make start-hf"
    puts "2. Start Hackerbot: ruby hackerbot.rb --irc-server localhost"
    puts "3. The bot will now use Hugging Face instead of Ollama!"
  else
    puts "\n❌ Configuration test failed. Please check the errors above."
  end

  exit(success ? 0 : 1)
end
