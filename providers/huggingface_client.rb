require 'net/http'
require 'json'
require 'timeout'
require_relative '../print.rb'
require_relative './llm_client.rb'

# Default configuration constants for Hugging Face
DEFAULT_HF_HOST = '127.0.0.1'
DEFAULT_HF_PORT = 8899
DEFAULT_HF_MODEL = 'EleutherAI/gpt-neo-125m'
DEFAULT_HF_TIMEOUT = 300  # 5 minutes for long generations

# Hugging Face client for local inference
class HuggingFaceClient < LLMClient
  def initialize(host = nil, port = nil, model = nil, system_prompt = nil, max_tokens = nil, temperature = nil, streaming = nil, timeout = nil)
    # Set defaults if not provided
    @host = host || DEFAULT_HF_HOST
    @port = port || DEFAULT_HF_PORT
    model = model || DEFAULT_HF_MODEL
    timeout = timeout || DEFAULT_HF_TIMEOUT

    # Call parent constructor
    super('huggingface', model, system_prompt, max_tokens, temperature, streaming)

    @base_url = "http://#{@host}:#{@port}"
    @timeout = timeout
    @server_ready = false
  end

  # Generate response from Hugging Face server
  def generate_response(prompt, stream_callback = nil)
    if @streaming && stream_callback
      return generate_streaming_response(prompt, stream_callback)
    end

    begin
      # Check if server is ready
      unless check_server_health
        Print.err "Hugging Face server is not ready at #{@base_url}"
        return nil
      end

      uri = URI("#{@base_url}/generate")
      Print.info "Generating response using Hugging Face model: #{@model}"
      Print.info "Prompt:"
      Print.info prompt

      request_body = {
        prompt: prompt,
        max_tokens: @max_tokens,
        temperature: @temperature,
        stream: false
      }

      http = Net::HTTP.new(@host, @port)
      http.open_timeout = 10
      http.read_timeout = @timeout
      request = Net::HTTP::Post.new(uri)
      request['Content-Type'] = 'application/json'
      request.body = request_body.to_json

      response = http.request(request)
      if response.code == '200'
        result = JSON.parse(response.body)
        response_text = result['response'].strip
        return response_text
      else
        Print.err "Hugging Face API error: #{response.code} - #{response.body}"
        return nil
      end
    rescue Net::TimeoutError => e
      Print.err "Hugging Face API timeout: #{e.message}"
      return nil
    rescue => e
      Print.err "Error calling Hugging Face API: #{e.message}"
      return nil
    end
  end

  # Generate streaming response from Hugging Face server
  def generate_streaming_response(prompt, stream_callback = nil)
    begin
      # Check if server is ready
      unless check_server_health
        Print.err "Hugging Face server is not ready at #{@base_url}"
        return nil
      end

      uri = URI("#{@base_url}/generate")
      Print.info "Generating streaming response using Hugging Face model: #{@model}"
      Print.info "Prompt:"
      Print.info prompt

      request_body = {
        prompt: prompt,
        max_tokens: @max_tokens,
        temperature: @temperature,
        stream: true
      }

      http = Net::HTTP.new(@host, @port)
      http.open_timeout = 10
      http.read_timeout = @timeout
      request = Net::HTTP::Post.new(uri)
      request['Content-Type'] = 'application/json'
      request.body = request_body.to_json

      full_response = ''

      http.request(request) do |response|
        if response.code == '200'
          response.read_body do |chunk|
            next if chunk.nil? || chunk.empty?

            begin
              # Remove any leading/trailing whitespace and newlines
              text_chunk = chunk.strip
              next if text_chunk.empty?

              full_response += text_chunk

              if stream_callback && !text_chunk.empty?
                stream_callback.call(text_chunk)
              end
            rescue => e
              Print.err "Error processing streaming chunk: #{e.message}"
              next
            end
          end
          return full_response.strip
        else
          Print.err "Hugging Face API error: #{response.code} - #{response.body}"
          return nil
        end
      end
    rescue Net::TimeoutError => e
      Print.err "Hugging Face API timeout during streaming: #{e.message}"
      return nil
    rescue => e
      Print.err "Error calling Hugging Face streaming API: #{e.message}"
      return nil
    end
  end

  # Test connection to Hugging Face server
  def test_connection
    check_server_health
  end

  # Check server health and model status
  def check_server_health
    begin
      uri = URI("#{@base_url}/health")
      http = Net::HTTP.new(@host, @port)
      http.open_timeout = 5
      http.read_timeout = 10
      request = Net::HTTP::Get.new(uri)
      response = http.request(request)

      if response.code == '200'
        health_data = JSON.parse(response.body)
        @server_ready = health_data['model_loaded'] == true
        if @server_ready
          Print.info "Hugging Face server is ready with model: #{health_data['model']}"
        else
          Print.warn "Hugging Face server is running but model not loaded"
        end
        return true
      else
        Print.err "Hugging Face server health check failed: #{response.code}"
        return false
      end
    rescue => e
      Print.err "Cannot connect to Hugging Face server: #{e.message}"
      @server_ready = false
      return false
    end
  end

  # Wait for server to be ready (with timeout)
  def wait_for_server_ready(timeout_seconds = 60)
    start_time = Time.now

    while Time.now - start_time < timeout_seconds
      if check_server_health && @server_ready
        return true
      end
      sleep(2)
    end

    Print.err "Timeout waiting for Hugging Face server to be ready"
    false
  end

  # Get model info
  def get_model_info
    begin
      uri = URI("#{@base_url}/models")
      http = Net::HTTP.new(@host, @port)
      http.open_timeout = 5
      http.read_timeout = 10
      request = Net::HTTP::Get.new(uri)
      response = http.request(request)

      if response.code == '200'
        return JSON.parse(response.body)
      else
        return nil
      end
    rescue => e
      Print.err "Error getting model info: #{e.message}"
      return nil
    end
  end
end
