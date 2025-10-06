#!/usr/bin/env ruby
"""
Test suite for Hugging Face client integration
Tests the HuggingFaceClient class and its integration with the server
"""

require 'test/unit'
require 'json'
require 'net/http'
require 'timeout'
require_relative '../providers/llm_client_factory'
require_relative '../providers/huggingface_client'

class TestHuggingFaceClient < Test::Unit::TestCase
  def setup
    @host = '127.0.0.1'
    @port = 8899
    @model = 'TinyLlama/TinyLlama-1.1B-Chat-v1.0'

    # Check if server is running
    @server_available = check_server_availability

    unless @server_available
      puts "⚠️  Hugging Face server not available. Some tests will be skipped."
      puts "   Start the server with: make start-hf"
    end
  end

  def teardown
    # Clean up if needed
  end

  def test_client_creation
    # Test creating Hugging Face client
    client = HuggingFaceClient.new(
      @host,
      @port,
      @model,
      "Test system prompt",
      100,
      0.7,
      false,
      30
    )

    assert_equal('huggingface', client.provider)
    assert_equal(@model, client.model)
    assert_equal('Test system prompt', client.system_prompt)
    assert_equal(100, client.max_tokens)
    assert_equal(0.7, client.temperature)
    assert_equal(false, client.streaming)
  end

  def test_factory_creation
    # Test creating client through factory
    client = LLMClientFactory.create_client('huggingface',
      host: @host,
      port: @port,
      model: @model,
      system_prompt: 'Factory test prompt',
      max_tokens: 50,
      temperature: 0.5,
      streaming: true,
      timeout: 60
    )

    assert_instance_of(HuggingFaceClient, client)
    assert_equal('huggingface', client.provider)
    assert_equal(@model, client.model)
    assert_equal(true, client.streaming)
  end

  def test_factory_alias
    # Test that 'hf' alias works
    client = LLMClientFactory.create_client('hf',
      host: @host,
      port: @port,
      model: @model
    )

    assert_instance_of(HuggingFaceClient, client)
  end

  def test_connection_failure
    # Test connection to non-existent server
    client = HuggingFaceClient.new('127.0.0.1', 9999, @model)

    assert_equal(false, client.test_connection)
  end

  def test_health_check
    skip "Server not available" unless @server_available

    client = HuggingFaceClient.new(@host, @port, @model)
    health = client.check_server_health

    assert_equal(true, health)
  end

  def test_model_info
    skip "Server not available" unless @server_available

    client = HuggingFaceClient.new(@host, @port, @model)
    info = client.get_model_info

    assert_not_nil(info)
    assert_equal(@model, info['current_model'])
    assert_equal(true, info['loaded'])
    assert_not_nil(info['device'])
  end

  def test_basic_generation
    skip "Server not available" unless @server_available

    client = HuggingFaceClient.new(
      @host,
      @port,
      @model,
      "You are a helpful assistant.",
      50,
      0.7,
      false,
      60
    )

    prompt = "What is 2 + 2?"
    response = client.generate_response(prompt)

    assert_not_nil(response)
    assert_kind_of(String, response)
    assert(response.length > 0)

    # Response should be reasonable (contains relevant information)
    assert_match(/4|four/i, response)
  end

  def test_streaming_generation
    skip "Server not available" unless @server_available

    client = HuggingFaceClient.new(
      @host,
      @port,
      @model,
      "You are a helpful assistant.",
      30,
      0.7,
      true,
      60
    )

    prompt = "Name a primary color."
    chunks = []
    full_response = ""

    stream_callback = lambda do |chunk|
      chunks << chunk
      full_response += chunk
    end

    response = client.generate_response(prompt, stream_callback)

    assert_not_nil(response)
    assert(chunks.length > 0)
    assert(full_response.length > 0)

    # Should contain a primary color
    assert_match(/red|blue|yellow/i, full_response)
  end

  def test_system_prompt_update
    client = HuggingFaceClient.new(@host, @port, @model)

    original_prompt = client.get_system_prompt
    new_prompt = "You are a cybersecurity expert."

    client.update_system_prompt(new_prompt)
    assert_equal(new_prompt, client.get_system_prompt)
    assert_not_equal(original_prompt, client.get_system_prompt)
  end

  def test_timeout_handling
    skip "Server not available" unless @server_available

    # Test with very short timeout
    client = HuggingFaceClient.new(@host, @port, @model, nil, 500, 0.7, false, 1)

    prompt = "Write a very long essay about artificial intelligence."
    response = client.generate_response(prompt)

    # Should return nil due to timeout or error (depending on server speed)
    # This test mainly ensures timeout handling doesn't crash
    assert(response.is_a?(String) || response.nil?)
  end

  def test_invalid_port
    client = HuggingFaceClient.new(@host, -1, @model)

    # Should handle invalid port gracefully
    assert_equal(false, client.test_connection)
  end

  def test_empty_prompt
    skip "Server not available" unless @server_available

    client = HuggingFaceClient.new(@host, @port, @model)

    # Empty prompt should be handled gracefully
    response = client.generate_response("")

    # May return nil or empty string depending on server implementation
    assert(response.nil? || response.empty?)
  end

  def test_large_prompt
    skip "Server not available" unless @server_available

    client = HuggingFaceClient.new(@host, @port, @model, nil, 10, 0.7, false, 60)

    # Very long prompt
    long_prompt = "Explain " + "computer science " * 100
    response = client.generate_response(long_prompt)

    # Should handle long prompts without crashing
    assert(response.is_a?(String) || response.nil?)
  end

  def test_temperature_variations
    skip "Server not available" unless @server_available

    prompt = "What is AI?"

    # Test different temperature settings
    temperatures = [0.1, 0.5, 1.0]
    responses = []

    temperatures.each do |temp|
      client = HuggingFaceClient.new(@host, @port, @model, nil, 30, temp, false, 60)
      response = client.generate_response(prompt)
      responses << response if response
    end

    # All should return valid responses
    assert_equal(temperatures.length, responses.length)
    responses.each do |response|
      assert_kind_of(String, response)
      assert(response.length > 0)
    end
  end

  def test_concurrent_requests
    skip "Server not available" unless @server_available

    # Test multiple concurrent requests
    threads = []
    results = []

    3.times do |i|
      threads << Thread.new do
        client = HuggingFaceClient.new(@host, @port, @model, nil, 20, 0.7, false, 60)
        response = client.generate_response("What is #{i + 1}?")
        results << response
      end
    end

    threads.each(&:join)

    # All should complete without errors
    assert_equal(3, results.length)
    results.each do |response|
      assert(response.is_a?(String) || response.nil?)
    end
  end

  def test_wait_for_server
    skip "Server not available" unless @server_available

    client = HuggingFaceClient.new(@host, @port, @model)

    # Should return true immediately since server is ready
    result = client.wait_for_server_ready(5)
    assert_equal(true, result)
  end

  def test_wait_for_server_timeout
    client = HuggingFaceClient.new(@host, 9999, @model)

    # Should return false due to timeout
    result = client.wait_for_server_ready(2)
    assert_equal(false, result)
  end

  def test_error_handling
    skip "Server not available" unless @server_available

    client = HuggingFaceClient.new(@host, @port, @model)

    # Test various error conditions that should be handled gracefully

    # Invalid JSON in request would be handled by the server
    # Network errors are handled in the client

    # Test with extremely short timeout to trigger timeout error
    client.timeout = 0.001
    response = client.generate_response("Test prompt")

    # Should handle timeout gracefully (return nil or partial response)
    assert(response.is_a?(String) || response.nil?)
  end

  private

  def check_server_availability
    begin
      uri = URI("http://#{@host}:#{@port}/health")
      http = Net::HTTP.new(@host, @port)
      http.open_timeout = 2
      http.read_timeout = 2
      request = Net::HTTP::Get.new(uri)
      response = http.request(request)
      return response.code == '200'
    rescue
      return false
    end
  end
end

# Run the tests if this file is executed directly
if __FILE__ == $0
  puts "🧪 Running Hugging Face Client Tests"
  puts "===================================="
  puts ""

  # Check if we're in the Nix environment
  unless ENV['GEM_HOME']
    puts "⚠️  Warning: Not in Nix development environment"
    puts "   Run with: nix develop --command ruby test/test_huggingface_client.rb"
    puts ""
  end

  # Run tests
  Test::Unit::AutoRunner.run
end
