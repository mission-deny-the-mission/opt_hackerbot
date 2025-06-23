#!/usr/bin/env ruby

# Test script for Ollama integration
require_relative 'hackerbot'

puts "Testing Ollama integration..."

# Test with default settings
client = OllamaClient.new
puts "Testing connection to Ollama..."
if client.test_connection
  puts "✓ Connection successful"
  
  puts "Testing response generation..."
  response = client.generate_response("Hello, how are you?")
  if response && !response.empty?
    puts "✓ Response generated: #{response}"
  else
    puts "✗ No response generated"
  end
else
  puts "✗ Connection failed - make sure Ollama is running"
  puts "  Run: ollama serve"
  puts "  Then: ollama pull llama2"
end

puts "\nTest completed." 