require 'net/http'
require 'json'
require './print.rb'

# Default configuration constants for Ollama
DEFAULT_SYSTEM_PROMPT = "You are a helpful cybersecurity training assistant.You help users learn about hacking techniques and security concepts. Be encouraging and educational in your responses. Keep explanations clear and practical."
DEFAULT_NUM_THREAD = 8
DEFAULT_KEEPALIVE = -1
DEFAULT_MAX_TOKENS = 150
DEFAULT_TEMPERATURE = 0.7
DEFAULT_STREAMING = true

# Ollama API client for LLM integration
class OllamaClient
  def initialize(host = 'localhost', port = 11434, model = 'gemma3:1b', system_prompt = nil, max_tokens = nil, temperature = nil, num_thread = nil, keepalive = nil, streaming = nil)
    @host = host
    @port = port
    @model = model
    @base_url = "http://#{@host}:#{@port}"
    @system_prompt = system_prompt || DEFAULT_SYSTEM_PROMPT
    @max_tokens = max_tokens || DEFAULT_MAX_TOKENS
    @temperature = temperature || DEFAULT_TEMPERATURE
    @num_thread = num_thread || DEFAULT_NUM_THREAD
    @keepalive = keepalive || DEFAULT_KEEPALIVE
    @streaming = streaming.nil? ? DEFAULT_STREAMING : streaming
  end

  # Only takes a prompt string and returns the response
  def generate_response(prompt, stream_callback = nil)
    if stream_callback
      return generate_streaming_response(prompt, stream_callback)
    end
    begin
      uri = URI("#{@base_url}/api/generate")
      Print.info "Generating response using model: #{@model}"
      Print.info "Prompt:"
      Print.info prompt
      request_body = {
        model: @model,
        prompt: prompt,
        stream: false,
        keepalive: @keepalive,
        options: {
          temperature: @temperature,
          top_p: 0.9,
          max_tokens: @max_tokens,
          num_thread: @num_thread
        }
      }
      http = Net::HTTP.new(@host, @port)
      http.open_timeout = 10
      http.read_timeout = 300
      request = Net::HTTP::Post.new(uri)
      request['Content-Type'] = 'application/json'
      request.body = request_body.to_json
      response = http.request(request)
      if response.code == '200'
        result = JSON.parse(response.body)
        response_text = result['response'].strip
        return response_text
      else
        Print.err "Ollama API error: #{response.code} - #{response.body}"
        return nil
      end
    rescue => e
      Print.err "Error calling Ollama API: #{e.message}"
      return nil
    end
  end

  def generate_streaming_response(prompt, stream_callback = nil)
    begin
      uri = URI("#{@base_url}/api/generate")
      Print.info "Generating streaming response using model: #{@model}"
      Print.info "Prompt:"
      Print.info prompt
      request_body = {
        model: @model,
        prompt: prompt,
        stream: true,
        keepalive: @keepalive,
        options: {
          temperature: @temperature,
          top_p: 0.9,
          max_tokens: @max_tokens,
          num_thread: @num_thread
        }
      }
      http = Net::HTTP.new(@host, @port)
      http.open_timeout = 10
      http.read_timeout = 300
      request = Net::HTTP::Post.new(uri)
      request['Content-Type'] = 'application/json'
      request.body = request_body.to_json
      full_response = ''
      current_line = ''
      http.request(request) do |response|
        if response.code == '200'
          response.read_body do |chunk|
            chunk.each_line do |line|
              line.strip!
              next if line.empty?
              begin
                data = JSON.parse(line)
                if data['response']
                  text_chunk = data['response']
                  full_response << text_chunk
                  current_line << text_chunk
                  if stream_callback && !text_chunk.empty?
                    stream_callback.call(text_chunk)
                  end
                  if current_line.include?("\n")
                    lines = current_line.split("\n", -1)
                    current_line = lines.last
                  end
                end
                if data['done']
                  if !current_line.strip.empty? && stream_callback
                    stream_callback.call(current_line.strip)
                  end
                  break
                end
              rescue JSON::ParserError => e
                Print.err "Failed to parse streaming response line: #{line}"
                next
              end
            end
          end
          return full_response.strip
        else
          Print.err "Ollama API error: #{response.code} - #{response.body}"
          return nil
        end
      end
    rescue => e
      Print.err "Error calling Ollama API: #{e.message}"
      return nil
    end
  end

  def test_connection
    begin
      uri = URI("#{@base_url}/api/tags")
      http = Net::HTTP.new(@host, @port)
      http.open_timeout = 5
      http.read_timeout = 10
      request = Net::HTTP::Get.new(uri)
      response = http.request(request)
      return response.code == '200'
    rescue => e
      Print.err "Cannot connect to Ollama: #{e.message}"
      return false
    end
  end

  # Update the system prompt dynamically
  def update_system_prompt(new_prompt)
    @system_prompt = new_prompt
  end

  # Get the current system prompt
  def get_system_prompt
    @system_prompt
  end
end 