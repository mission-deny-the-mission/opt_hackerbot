#!/usr/bin/env ruby

require './hackerbot.rb'

puts "Testing Ollama Streaming Functionality"
puts "=" * 40

# Initialize Ollama client with streaming enabled
client = OllamaClient.new('localhost', 11434, 'gemma3:1b', nil, nil, nil, nil, nil, true)

# Test connection
unless client.test_connection
  puts "❌ Cannot connect to Ollama. Make sure it's running on localhost:11434"
  exit 1
end

puts "✅ Connected to Ollama successfully"

# Test streaming response
puts "\nTesting streaming response..."
puts "Sending: 'Tell me about cybersecurity in 3 short sentences'"

stream_callback = Proc.new do |chunk|
  print chunk
  $stdout.flush
end

response = client.generate_response(
  "Tell me about cybersecurity in 3 short sentences", 
  "", 
  "test_user", 
  stream_callback
)

puts "" # Print a newline after streaming output
puts "\n✅ Streaming test completed!"
puts "Full response: #{response}"

# Test non-streaming response for comparison
puts "\n" + "=" * 40
puts "Testing non-streaming response for comparison..."

client_no_stream = OllamaClient.new('localhost', 11434, 'gemma3:1b', nil, nil, nil, nil, nil, false)

response_no_stream = client_no_stream.generate_response(
  "Tell me about cybersecurity in 3 short sentences", 
  "", 
  "test_user"
)

puts "Non-streaming response: #{response_no_stream}"
puts "\n✅ Test completed!" 