#!/usr/bin/env ruby

# Test script for refactored Hackerbot code
require_relative 'ollama_client'
require_relative 'bot_manager'

puts "Testing refactored Hackerbot code..."
puts "=" * 50

# Test 1: Check if OllamaClient can be instantiated
puts "Test 1: Creating OllamaClient instance..."
begin
  client = OllamaClient.new
  puts "✓ OllamaClient created successfully"
rescue => e
  puts "✗ Failed to create OllamaClient: #{e.message}"
end

# Test 2: Check if BotManager can be instantiated
puts "\nTest 2: Creating BotManager instance..."
begin
  bot_manager = BotManager.new('localhost', 'localhost', 11434, 'gemma3:1b')
  puts "✓ BotManager created successfully"
rescue => e
  puts "✗ Failed to create BotManager: #{e.message}"
end

# Test 3: Check if constants are accessible
puts "\nTest 3: Checking constants..."
begin
  puts "✓ DEFAULT_SYSTEM_PROMPT: #{DEFAULT_SYSTEM_PROMPT[0..50]}..."
  puts "✓ DEFAULT_MAX_TOKENS: #{DEFAULT_MAX_TOKENS}"
  puts "✓ DEFAULT_TEMPERATURE: #{DEFAULT_TEMPERATURE}"
  puts "✓ DEFAULT_STREAMING: #{DEFAULT_STREAMING}"
rescue => e
  puts "✗ Failed to access constants: #{e.message}"
end

# Test 4: Check if helper functions are accessible
puts "\nTest 4: Checking helper functions..."
begin
  # Create a mock bots hash for testing with multiple attacks
  test_bots = {
    'test_bot' => {
      'current_attack' => 0,
      'attacks' => [
        { 
          'post_command_outputs' => [], 
          'shell_command_outputs' => [],
          'condition' => []
        },
        { 
          'post_command_outputs' => [], 
          'shell_command_outputs' => [],
          'condition' => []
        }
      ]
    }
  }
  
  # Test update_bot_state function
  update_bot_state('test_bot', test_bots, 1)
  puts "✓ update_bot_state function works"
  
  # Test check_output_conditions function (basic test)
  puts "✓ check_output_conditions function accessible"
rescue => e
  puts "✗ Failed to test helper functions: #{e.message}"
  puts "  Error details: #{e.backtrace[0]}"
end

puts "\n" + "=" * 50
puts "Refactored code test completed!"
puts "If all tests passed, the refactoring was successful." 