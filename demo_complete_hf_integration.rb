#!/usr/bin/env ruby
"""
Comprehensive Working Example: Hugging Face Integration with Hackerbot
This script demonstrates the complete end-to-end Hugging Face integration
"""

require_relative 'providers/llm_client_factory'
require_relative 'print.rb'
require 'json'
require 'net/http'
require 'uri'

class HuggingFaceIntegrationDemo
  def initialize
    @server_host = '127.0.0.1'
    @server_port = 8899
    @model_name = 'EleutherAI/gpt-neo-125m'
    @server_pid = nil
  end

  def demo_title
    puts "🤖 Hugging Face Integration Demo"
    puts "=================================="
    puts "This demo shows the complete working integration between Hackerbot and local Hugging Face inference"
    puts ""
  end

  def check_environment
    puts "🔍 Checking environment..."

    # Check if Hugging Face environment exists
    unless File.exist?('hf_env/bin/python')
      puts "❌ Hugging Face environment not found"
      puts "   Run: make setup-hf"
      return false
    end

    # Check if server script exists
    unless File.exist?('hf_server/hf_inference_server.py')
      puts "❌ Hugging Face server script not found"
      return false
    end

    puts "✅ Environment looks good"
    return true
  end

  def start_hf_server
    puts "🚀 Starting Hugging Face inference server..."

    # Stop any existing server
    stop_server

    # Start server in background
    server_command = "cd hf_server && source ../hf_env/bin/activate && python3 hf_inference_server.py --model #{@model_name} --host #{@server_host} --port #{@server_port} --device cpu"

    begin
      @server_pid = spawn(server_command, [:out, :err] => "/tmp/hf_server_demo.log")
      Process.detach(@server_pid)

      # Wait for server to start
      puts "   Waiting for server to start..."
      sleep(5)

      # Check if server is responding
      if test_server_health
        puts "✅ Hugging Face server started successfully (PID: #{@server_pid})"
        return true
      else
        puts "❌ Server failed to start properly"
        puts "   Check logs: tail -f /tmp/hf_server_demo.log"
        return false
      end

    rescue => e
      puts "❌ Failed to start server: #{e.message}"
      return false
    end
  end

  def test_server_health
    begin
      uri = URI("http://#{@server_host}:#{@server_port}/health")
      response = Net::HTTP.get_response(uri)

      if response.code == '200'
        health_data = JSON.parse(response.body)
        puts "   Server health: #{health_data['status']}"
        puts "   Model: #{health_data['model']}"
        puts "   Device: #{health_data['device']}"
        puts "   Model loaded: #{health_data['model_loaded']}"
        return health_data['model_loaded']
      else
        puts "   Server responded with code: #{response.code}"
        return false
      end
    rescue => e
      puts "   Health check failed: #{e.message}"
      return false
    end
  end

  def test_direct_api
    puts "\n🌐 Testing direct HTTP API..."

    test_prompts = [
      "What is cybersecurity?",
      "Explain what a firewall does",
      "Name a common network security practice"
    ]

    test_prompts.each_with_index do |prompt, i|
      puts "   Test #{i + 1}: #{prompt}"

      begin
        uri = URI("http://#{@server_host}:#{@server_port}/generate")
        request_data = {
          prompt: prompt,
          max_tokens: 20,
          temperature: 0.7,
          stream: false
        }.to_json

        http = Net::HTTP.new(@server_host, @server_port)
        request = Net::HTTP::Post.new(uri)
        request['Content-Type'] = 'application/json'
        request.body = request_data

        response = http.request(request)

        if response.code == '200'
          result = JSON.parse(response.body)
          puts "   ✅ Response: #{result['response']}"
        else
          puts "   ❌ API error: #{response.code} - #{response.body}"
        end

      rescue => e
        puts "   ❌ Request failed: #{e.message}"
      end

      puts ""
    end
  end

  def test_ruby_client
    puts "💎 Testing Ruby client integration..."

    begin
      # Create Hugging Face client
      client = LLMClientFactory.create_client('huggingface',
        host: @server_host,
        port: @server_port,
        model: @model_name,
        max_tokens: 25,
        temperature: 0.7,
        streaming: false,
        timeout: 30
      )

      puts "   ✅ Ruby client created successfully"

      # Test connection
      if client.test_connection
        puts "   ✅ Client connection test passed"
      else
        puts "   ❌ Client connection test failed"
        return false
      end

      # Test generation
      test_prompts = [
        "The best thing about AI is",
        "In cybersecurity, the most important concept is",
        "Network administrators should always"
      ]

      test_prompts.each_with_index do |prompt, i|
        puts "   Generation test #{i + 1}: #{prompt}"

        response = client.generate_response(prompt)

        if response
          puts "   ✅ Ruby response: #{response}"
        else
          puts "   ❌ Ruby generation failed"
        end
        puts ""
      end

      return true

    rescue => e
      puts "   ❌ Ruby client test failed: #{e.message}"
      return false
    end
  end

  def test_hackerbot_integration
    puts "🤖 Testing Hackerbot CLI integration..."

    # Test Hackerbot argument parsing
    test_commands = [
      "ruby hackerbot.rb --help | grep -q 'hf-host' && echo '✅ HF options in help' || echo '❌ HF options missing'",
      "ruby hackerbot.rb --llm-provider huggingface --hf-model #{@model_name} --hf-host #{@server_host} --hf-port #{@server_port} --irc-server localhost --streaming false 2>&1 | head -5"
    ]

    test_commands.each do |cmd|
      puts "   Running: #{cmd}"
      result = `#{cmd}`
      puts "   Result: #{result.strip}"
      puts ""
    end
  end

  def test_configuration
    puts "📄 Testing configuration files..."

    config_file = 'config/test_hf_bot.xml'

    if File.exist?(config_file)
      puts "   ✅ Test configuration file exists: #{config_file}"

      # Parse and validate configuration
      require 'nokogiri'
      doc = File.open(config_file) { |f| Nokogiri::XML(f) }

      provider = doc.at_xpath('//llm_provider')&.text
      model = doc.at_xpath('//llm_config/model')&.text
      host = doc.at_xpath('//llm_config/host')&.text
      port = doc.at_xpath('//llm_config/port')&.text

      puts "   Configuration details:"
      puts "     Provider: #{provider}"
      puts "     Model: #{model}"
      puts "     Host: #{host}"
      puts "     Port: #{port}"

      if provider == 'huggingface' && host == @server_host && port.to_i == @server_port
        puts "   ✅ Configuration is valid"
        return true
      else
        puts "   ❌ Configuration has issues"
        return false
      end
    else
      puts "   ❌ Configuration file not found: #{config_file}"
      return false
    end
  end

  def show_usage_examples
    puts "\n📚 Usage Examples"
    puts "=================="
    puts ""
    puts "1. Setup Hugging Face environment (one-time):"
    puts "   make setup-hf"
    puts ""
    puts "2. Start Hugging Face server:"
    puts "   make start-hf"
    puts ""
    puts "3. Start Hackerbot with Hugging Face:"
    puts "   make bot-hf"
    puts ""
    puts "4. Start Hackerbot with Hugging Face + RAG + CAG:"
    puts "   make bot-hf-rag-cag"
    puts ""
    puts "5. Manual startup:"
    puts "   # Terminal 1: Start server"
    puts "   source hf_env/bin/activate"
    puts "   cd hf_server"
    puts "   python3 hf_inference_server.py --model EleutherAI/gpt-neo-125m"
    puts ""
    puts "   # Terminal 2: Start Hackerbot"
    puts "   ruby hackerbot.rb --llm-provider huggingface --hf-model EleutherAI/gpt-neo-125m --irc-server localhost"
    puts ""
    puts "6. Using configuration file:"
    puts "   ruby hackerbot.rb --config config/test_hf_bot.xml --irc-server localhost"
    puts ""
    puts "7. Different models:"
    puts "   # Small model (fast, good for testing)"
    puts "   ruby hackerbot.rb --llm-provider huggingface --hf-model EleutherAI/gpt-neo-125m"
    puts ""
    puts "   # Larger model (better quality, requires more resources)"
    puts "   ruby hackerbot.rb --llm-provider huggingface --hf-model TinyLlama/TinyLlama-1.1B-Chat-v1.0"
    puts ""
  end

  def show_troubleshooting
    puts "\n🔧 Troubleshooting"
    puts "=================="
    puts ""
    puts "Common Issues and Solutions:"
    puts ""
    puts "1. Server won't start:"
    puts "   - Check if port 8899 is in use: lsof -i :8899"
    puts "   - Check server logs: tail -f /tmp/hf_server.log"
    puts "   - Make sure environment is setup: make setup-hf"
    puts ""
    puts "2. Model loading fails:"
    puts "   - Check internet connection for model download"
    puts "   - Try a smaller model: EleutherAI/gpt-neo-125m"
    puts "   - Check available disk space (models can be 2GB+)"
    puts ""
    puts "3. Ruby client can't connect:"
    puts "   - Verify server is running: curl http://127.0.0.1:8899/health"
    puts "   - Check firewall settings"
    puts "   - Ensure correct host/port in configuration"
    puts ""
    puts "4. Hackerbot arguments not recognized:"
    puts "   - Update your hackerbot.rb with latest changes"
    puts "   - Check: ruby hackerbot.rb --help | grep hf-"
    puts ""
    puts "5. Slow responses:"
    puts "   - Use smaller model for faster inference"
    puts "   - Reduce max_tokens parameter"
    puts "   - Consider using GPU acceleration if available"
    puts ""
  end

  def stop_server
    if @server_pid
      begin
        Process.kill('TERM', @server_pid)
        sleep(1)
        Process.kill('KILL', @server_pid) if Process.running?(@server_pid)
        puts "✅ Server stopped"
      rescue
        # Process might already be stopped
      end
      @server_pid = nil
    end
  end

  def run_demo
    demo_title

    # Run all tests
    tests = [
      { name: "Environment Check", method: :check_environment },
      { name: "Start Server", method: :start_hf_server },
      { name: "Test Direct API", method: :test_direct_api },
      { name: "Test Ruby Client", method: :test_ruby_client },
      { name: "Test Configuration", method: :test_configuration },
      { name: "Test Hackerbot CLI", method: :test_hackerbot_integration }
    ]

    passed = 0
    failed = 0

    tests.each do |test|
      puts "\n🧪 Running: #{test[:name]}"
      puts "-" * 50

      begin
        result = send(test[:method])
        if result
          puts "✅ #{test[:name]}: PASSED"
          passed += 1
        else
          puts "❌ #{test[:name]}: FAILED"
          failed += 1
        end
      rescue => e
        puts "❌ #{test[:name]}: ERROR - #{e.message}"
        failed += 1
      end
    end

    # Summary
    puts "\n🎯 Demo Summary"
    puts "=" * 50
    puts "Passed: #{passed}"
    puts "Failed: #{failed}"
    puts "Total:  #{passed + failed}"

    if failed == 0
      puts "\n🎉 All tests passed! Hugging Face integration is working perfectly!"
      puts "\n🚀 You can now use:"
      puts "   make start-hf    # Start Hugging Face server"
      puts "   make bot-hf      # Start Hackerbot with Hugging Face"
    else
      puts "\n⚠️  Some tests failed. Check the troubleshooting section above."
    end

    # Show usage examples and troubleshooting
    show_usage_examples
    show_troubleshooting

    # Cleanup
    puts "\n🧹 Cleaning up..."
    stop_server

    return failed == 0
  end
end

# Main execution
if __FILE__ == $0
  demo = HuggingFaceIntegrationDemo.new
  success = demo.run_demo

  exit(success ? 0 : 1)
end
