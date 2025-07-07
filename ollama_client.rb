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
    @chat_history = []
    @user_chat_histories = {}
    @max_history_length = 10  # Keep last 10 exchanges
    @max_tokens = max_tokens || DEFAULT_MAX_TOKENS
    @temperature = temperature || DEFAULT_TEMPERATURE
    @num_thread = num_thread || DEFAULT_NUM_THREAD
    @keepalive = keepalive || DEFAULT_KEEPALIVE
    @streaming = streaming.nil? ? DEFAULT_STREAMING : streaming
  end

  def add_to_history(user_message, assistant_response, user_id = nil)
    if user_id
      # Per-user history
      @user_chat_histories[user_id] ||= []
      @user_chat_histories[user_id] << { user: user_message, assistant: assistant_response }
      # Keep only the last max_history_length exchanges
      if @user_chat_histories[user_id].length > @max_history_length
        @user_chat_histories[user_id] = @user_chat_histories[user_id].last(@max_history_length)
      end
    else
      # Global history (for backward compatibility)
      @chat_history << { user: user_message, assistant: assistant_response }
      # Keep only the last max_history_length exchanges
      if @chat_history.length > @max_history_length
        @chat_history = @chat_history.last(@max_history_length)
      end
    end
  end

  def get_chat_context(user_id = nil)
    if user_id && @user_chat_histories[user_id]
      history = @user_chat_histories[user_id]
    else
      history = @chat_history
    end
    
    return '' if history.empty?
    
    context_parts = history.map do |exchange|
      "User: #{exchange[:user]}\nAssistant: #{exchange[:assistant]}"
    end
    
    context_parts.join("\n\n")
  end

  def clear_user_history(user_id)
    @user_chat_histories.delete(user_id) if user_id
  end

  def generate_response(message, context = '', user_id = nil, stream_callback = nil)
    if stream_callback
      return generate_streaming_response(message, context, user_id, stream_callback)
    end
    
    begin
      uri = URI("#{@base_url}/api/generate")
      
      # Create a system prompt that makes the bot act like a helpful assistant
      system_prompt = @system_prompt
      
      # Get chat history context for the specific user
      chat_context = get_chat_context(user_id)
      
      # Combine context, chat history, and message
      full_prompt = if context.empty? && chat_context.empty?
        "#{system_prompt}\n\nUser: #{message}\nAssistant:"
      elsif context.empty?
        "#{system_prompt}\n\nChat History:\n#{chat_context}\n\nUser: #{message}\nAssistant:"
      elsif chat_context.empty?
        "#{system_prompt}\n\nContext: #{context}\n\nUser: #{message}\nAssistant:"
      else
        "#{system_prompt}\n\nContext: #{context}\n\nChat History:\n#{chat_context}\n\nUser: #{message}\nAssistant:"
      end

      Print.info "Generating response using model: #{@model}"
      Print.info "Full prompt:"
      Print.info full_prompt

      request_body = {
        model: @model,
        prompt: full_prompt,
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
        
        # Add this exchange to chat history for the specific user
        add_to_history(message, response_text, user_id)
        
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

  def generate_streaming_response(message, context = '', user_id = nil, stream_callback = nil)
    begin
      uri = URI("#{@base_url}/api/generate")
      
      # Create a system prompt that makes the bot act like a helpful assistant
      system_prompt = @system_prompt
      
      # Get chat history context for the specific user
      chat_context = get_chat_context(user_id)
      
      # Combine context, chat history, and message
      full_prompt = if context.empty? && chat_context.empty?
        "#{system_prompt}\n\nUser: #{message}\nAssistant:"
      elsif context.empty?
        "#{system_prompt}\n\nChat History:\n#{chat_context}\n\nUser: #{message}\nAssistant:"
      elsif chat_context.empty?
        "#{system_prompt}\n\nContext: #{context}\n\nUser: #{message}\nAssistant:"
      else
        "#{system_prompt}\n\nContext: #{context}\n\nChat History:\n#{chat_context}\n\nUser: #{message}\nAssistant:"
      end

      Print.info "Generating streaming response using model: #{@model}"
      Print.info "Full prompt:"
      Print.info full_prompt

      request_body = {
        model: @model,
        prompt: full_prompt,
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

      # Use a block to handle the streaming response
      full_response = ''
      current_line = ''
      
      http.request(request) do |response|
        if response.code == '200'
          response.read_body do |chunk|
            # Process each chunk as it arrives
            chunk.each_line do |line|
              line.strip!
              next if line.empty?
              
              begin
                data = JSON.parse(line)
                if data['response']
                  text_chunk = data['response']
                  full_response << text_chunk
                  current_line << text_chunk
                  
                  # Send the chunk immediately for more responsive streaming
                  if stream_callback && !text_chunk.empty?
                    stream_callback.call(text_chunk)
                  end
                  
                  # Also handle complete lines for better formatting
                  if current_line.include?("\n")
                    lines = current_line.split("\n", -1)
                    # Keep the last (potentially incomplete) line
                    current_line = lines.last
                  end
                end
                
                # Check if this is the final response
                if data['done']
                  # Send any remaining content in current_line
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
          
          # Add this exchange to chat history for the specific user
          add_to_history(message, full_response.strip, user_id)
          
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
end 