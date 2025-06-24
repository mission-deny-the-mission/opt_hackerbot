require 'ircinch'
require 'nokogiri'
require 'nori'
require './print.rb'
require 'open3'
require 'net/http'
require 'json'
require 'getoptlong'
require 'thwait'

# Ollama API client for LLM integration
class OllamaClient
  def initialize(host = 'localhost', port = 11434, model = 'gemma3:1b', system_prompt = nil, max_tokens = 150, temperature = 0.7)
    @host = host
    @port = port
    @model = model
    @base_url = "http://#{@host}:#{@port}"
    @system_prompt = system_prompt || "You are a helpful AI assistant. Respond naturally and conversationally to user messages. Keep responses concise and relevant."
    @chat_history = []
    @user_chat_histories = {}
    @max_history_length = 10  # Keep last 10 exchanges
    @max_tokens = 150
    @temperature = 0.7
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

  def generate_response(message, context = '', user_id = nil)
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

      puts full_prompt

      request_body = {
        model: @model,
        prompt: full_prompt,
        stream: false,
        options: {
          temperature: 0.7,
          top_p: 0.9,
          max_tokens: 150,
          num_thread: 8
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

def update_bot_state(bot_name, bots, current_attack)
  bots[bot_name]['current_attack'] = current_attack
  bots[bot_name]['current_quiz'] = nil
  bots[bot_name]['attacks'][current_attack]['post_command_outputs'] ||= []
  bots[bot_name]['attacks'][current_attack]['shell_command_outputs'] ||= []
end

def check_output_conditions(bot_name, bots, current, lines, m)
  bots[bot_name]['attacks'][current]['shell_command_outputs'] ||= []
  bots[bot_name]['attacks'][current]['shell_command_outputs'] << lines

  condition_met = false
  bots[bot_name]['attacks'][current]['condition'].each do |condition|
    if !condition_met && condition.key?('output_matches') && lines =~ /#{condition['output_matches']}/m
      condition_met = true
      m.reply "#{condition['message']}"
    end
    if !condition_met && condition.key?('output_not_matches') && lines !~ /#{condition['output_not_matches']}/m
      condition_met = true
      m.reply "#{condition['message']}"
    end
    if !condition_met && condition.key?('output_equals') && lines.chomp == condition['output_equals']
      condition_met = true
      m.reply "#{condition['message']}"
    end

    if condition_met
      if condition.key?('trigger_next_attack')
        if bots[bot_name]['current_attack'] < bots[bot_name]['attacks'].length - 1
          current = bots[bot_name]['current_attack'] + 1
          update_bot_state(bot_name, bots, current)

          sleep(1)
          if bots[bot_name]['messages'].key?('show_attack_numbers')
            m.reply "** ##{current + 1} **"
          end
          m.reply bots[bot_name]['attacks'][current]['prompt']
        else
          m.reply bots[bot_name]['messages']['last_attack'].sample
        end
      end

      if condition.key?('trigger_quiz')
        m.reply bots[bot_name]['attacks'][current]['quiz']['question']
        m.reply bots[bot_name]['messages']['say_answer']
        bots[bot_name]['current_quiz'] = 0
      end
      # stop processing conditions, once we meet one
      break
    end
  end
  unless condition_met
    if bots[bot_name]['attacks'][current]['else_condition']
      m.reply bots[bot_name]['attacks'][current]['else_condition']['message']
    end
  end
  current
end

def read_bots (irc_server_ip_address)
  bots = {}
  Dir.glob("config/*.xml").each do |file|
    print "#{file}"

    begin
      doc = Nokogiri::XML(File.read(file))
      if doc.errors.any?
        Print.err doc.errors
      end
    rescue
      Print.err "Failed to read hackerbot file (#{file})"
      print "Failed to read hackerbot file (#{file})"

      exit
    end
    #
    # # TODO validate scenario XML against schema
    # begin
    #   xsd = Nokogiri::XML::Schema(File.read(schema_file))
    #   xsd.validate(doc).each do |error|
    #     Print.err "Error in bot config file (#{file}):"
    #     Print.err '    ' + error.message
    #     exit
    #   end
    # rescue Exception => e
    #   Print.err "Failed to validate bot config file (#{file}): against schema (#{schema_file})"
    #   Print.err e.message
    #   exit
    # end

    # remove xml namespaces for ease of processing
    doc.remove_namespaces!

    doc.xpath('/hackerbot').each_with_index do |hackerbot|

      bot_name = hackerbot.at_xpath('name').text
      Print.debug bot_name
      bots[bot_name] = {}

      get_shell = hackerbot.at_xpath('get_shell').text
      Print.debug get_shell
      bots[bot_name]['get_shell'] = get_shell

      bots[bot_name]['messages'] = Nori.new.parse(hackerbot.at_xpath('//messages').to_s)['messages']
      Print.debug bots[bot_name]['messages'].to_s

      bots[bot_name]['attacks'] = []
      hackerbot.xpath('//attack').each do |attack|
        bots[bot_name]['attacks'].push Nori.new.parse(attack.to_s)['attack']
      end
      bots[bot_name]['current_attack'] = 0

      bots[bot_name]['current_quiz'] = nil

      Print.debug bots[bot_name]['attacks'].to_s

      # Initialize per-user chat history storage
      bots[bot_name]['user_chat_history'] = {}

      # Initialize Ollama client for this bot
      # You can customize the model per bot by adding a model attribute to the XML
      model_name = hackerbot.at_xpath('ollama_model')&.text || ollama_model
      ollama_host_config = hackerbot.at_xpath('ollama_host')&.text || ollama_host
      ollama_port_config = (hackerbot.at_xpath('ollama_port')&.text || ollama_port.to_s).to_i
      ollama_system_prompt = hackerbot.at_xpath('system_prompt')&.text || "You are a helpful AI assistant. Respond naturally and conversationally to user messages. Keep responses concise and relevant."
      max_tokens = (hackerbot.at_xpath('max_tokens')&.text || 150).to_i
      temperature = (hackerbot.at_xpath('model_temperature')&.text || 0.7).to_f
      bots[bot_name]['chat_ai'] = OllamaClient.new(ollama_host_config, ollama_port_config, model_name, ollama_system_prompt, max_tokens, temperature)
      
      # Test connection to Ollama
      unless bots[bot_name]['chat_ai'].test_connection
        Print.err "Warning: Cannot connect to Ollama for bot #{bot_name}. Chat responses may not work."
      end

      bots[bot_name]['bot'] = Cinch::Bot.new do
        configure do |c|
          c.nick = bot_name
          c.server = irc_server_ip_address
          # joins a channel named after the bot, and #bots
          c.channels = ["##{bot_name}", '#bots']
        end

        on :message, /hello/i do |m|
          m.reply "Hello, #{m.user.nick} (#{m.user.host})."
          m.reply bots[bot_name]['messages']['greeting']
          current = bots[bot_name]['current_attack']

          # prompt for the first attack
          if bots[bot_name]['messages'].key?('show_attack_numbers')
            m.reply "** ##{current + 1} **"
          end
          m.reply bots[bot_name]['attacks'][current]['prompt']
          m.reply bots[bot_name]['messages']['say_ready'].sample
        end

        on :message, /help/i do |m|
          m.reply bots[bot_name]['messages']['help']
        end

        on :message, 'next' do |m|
          m.reply bots[bot_name]['messages']['next'].sample

          # is this the last one?
          if bots[bot_name]['current_attack'] < bots[bot_name]['attacks'].length - 1
            bots[bot_name]['current_attack'] += 1
            current = bots[bot_name]['current_attack']
            update_bot_state(bot_name, bots, current)

            # prompt for current hack
            if bots[bot_name]['messages'].key?('show_attack_numbers')
              m.reply "** ##{current + 1} **"
            end
            m.reply bots[bot_name]['attacks'][current]['prompt']
            m.reply bots[bot_name]['messages']['say_ready'].sample
          else
            m.reply bots[bot_name]['messages']['last_attack'].sample
          end

        end

        on :message, /^(goto|attack) [0-9]+$/i do |m|
          m.reply bots[bot_name]['messages']['goto'].sample
          requested_index = m.message.chomp().split[1].to_i - 1

          Print.debug "requested_index = #{requested_index}, bots[bot_name]['attacks'].length = #{bots[bot_name]['attacks'].length}"

          # is this a valid attack number?
          if requested_index < bots[bot_name]['attacks'].length
            update_bot_state(bot_name, bots, requested_index)
            current = bots[bot_name]['current_attack']

            # prompt for current hack
            if bots[bot_name]['messages'].key?('show_attack_numbers')
              m.reply "** ##{current + 1} **"
            end
            m.reply bots[bot_name]['attacks'][current]['prompt']
            m.reply bots[bot_name]['messages']['say_ready'].sample
          else
            m.reply bots[bot_name]['messages']['invalid']
          end

        end

        on :message, /^(the answer is|answer):? .+$/i do |m|
          answer = m.message.chomp().match(/(?:the )?answer(?: is)?:? (.+)$/i)[1]
          current = bots[bot_name]['current_attack']
        
          quiz = nil
          if bots[bot_name]['attacks'][current].key?('quiz') && bots[bot_name]['attacks'][current]['quiz'].key?('answer')
            quiz = bots[bot_name]['attacks'][current]['quiz']
          end
        
          if quiz != nil
            correct_answer = quiz['answer'].clone
            if bots[bot_name]['attacks'][current].key?('post_command_output')
              post_outputs = bots[bot_name]['attacks'][current]['post_command_outputs'].map(&:strip).join('|')
              correct_answer.gsub!(/{{post_command_output}}/, post_outputs)
            end
            if bots[bot_name]['attacks'][current].key?('get_shell_command_output')
              shell_outputs = bots[bot_name]['attacks'][current]['shell_command_outputs'].map { |output| output.lines.first.to_s.strip }.join('|')
              correct_answer.gsub!(/{{shell_command_output_first_line}}/, shell_outputs)
            end
            if bots[bot_name]['attacks'][current].key?('pre_shell')
              pre_shell_outputs = bots[bot_name]['attacks'][current]['pre_shell_command_outputs'] || []
              pre_shell_output = pre_shell_outputs.map { |output| output.lines.first.to_s.strip }.join('|')
              correct_answer.gsub!(/{{pre_shell_command_output_first_line}}/, pre_shell_output)
            end
            correct_answer.chomp!
            Print.debug "#{correct_answer}====#{answer}"
        
            if answer.strip.match?(/^(?:#{correct_answer})$/i)
              m.reply bots[bot_name]['messages']['correct_answer']
              m.reply quiz['correct_answer_response']
        
              if quiz.key?('trigger_next_attack')
                if bots[bot_name]['current_attack'] < bots[bot_name]['attacks'].length - 1
                  bots[bot_name]['current_attack'] += 1
                  current = bots[bot_name]['current_attack']
                  update_bot_state(bot_name, bots, current)
        
                  sleep(1)
                  if bots[bot_name]['messages'].key?('show_attack_numbers')
                    m.reply "** ##{current + 1} **"
                  end
                  m.reply bots[bot_name]['attacks'][current]['prompt']
                  m.reply bots[bot_name]['messages']['say_ready'].sample
                else
                  m.reply bots[bot_name]['messages']['last_attack'].sample
                end
              end
            else
              m.reply "#{bots[bot_name]['messages']['incorrect_answer']} (#{answer})"
            end
          else
            m.reply bots[bot_name]['messages']['no_quiz']
          end
        end

        on :message, 'previous' do |m|
          m.reply bots[bot_name]['messages']['previous'].sample

          # is this the last one?
          if bots[bot_name]['current_attack'] > 0
            bots[bot_name]['current_attack'] -= 1
            current = bots[bot_name]['current_attack']
            update_bot_state(bot_name, bots, current)

            # prompt for current hack
            if bots[bot_name]['messages'].key?('show_attack_numbers')
              m.reply "** ##{current + 1} **"
            end
            m.reply bots[bot_name]['attacks'][current]['prompt']
            m.reply bots[bot_name]['messages']['say_ready'].sample

          else
            m.reply bots[bot_name]['messages']['first_attack'].sample
          end

        end

        on :message, 'list' do |m|
          bots[bot_name]['attacks'].each_with_index {|val, index|
            uptohere = ''
            if index == bots[bot_name]['current_attack']
              uptohere = '--> '
            end

            m.reply "#{uptohere}attack #{index+1}: #{val['prompt']}"
          }
        end

        on :message, 'clear_history' do |m|
          user_id = m.user.nick
          bots[bot_name]['chat_ai'].clear_user_history(user_id)
          m.reply "Chat history cleared for #{user_id}."
        end

        on :message, 'show_history' do |m|
          user_id = m.user.nick
          chat_context = bots[bot_name]['chat_ai'].get_chat_context(user_id)
          if chat_context.empty?
            m.reply "No chat history found for #{user_id}."
          else
            m.reply "Chat history for #{user_id}:"
            m.reply chat_context
          end
        end

        # fallback to Ollama LLM responses
        on :message do |m|

          # Only process messages not related to controlling attacks
          if m.message !~ /hello|help|next|previous|list|clear_history|show_history|^(goto|attack) [0-9]|(the answer is|answer)/
            reaction = ''
            begin
              # Use Ollama to generate a response with user-specific chat history
              user_id = m.user.nick
              
              # Add current attack context if available
              current_attack = bots[bot_name]['current_attack']
              attack_context = ''
              if current_attack < bots[bot_name]['attacks'].length
                attack_context = "Current attack (#{current_attack + 1}): #{bots[bot_name]['attacks'][current_attack]['prompt']}"
              end
              
              reaction = bots[bot_name]['chat_ai'].generate_response(m.message, attack_context, user_id)
            rescue Exception => e
              puts e.message
              puts e.backtrace.inspect
              reaction = ''
            end
            if reaction != '' && reaction != nil
              m.reply reaction
            else
              if m.message.include?('?')
                m.reply bots[bot_name]['messages']['non_answer']
              end
            end
          end

        end


        on :message, 'ready' do |m|
          m.reply bots[bot_name]['messages']['getting_shell'].sample
          current = bots[bot_name]['current_attack']

          if bots[bot_name]['attacks'][current].key?('pre_shell')
            pre_shell_cmd = bots[bot_name]['attacks'][current]['pre_shell'].to_s.clone
            pre_shell_cmd.gsub!(/{{chat_ip_address}}/, m.user.host.to_s)

            pre_output = `#{pre_shell_cmd}`
            unless bots[bot_name]['attacks'][current].key?('suppress_command_output_feedback')
              m.reply "FYI: #{pre_output}"
            end
            bots[bot_name]['attacks'][current]['pre_shell_command_outputs'] ||= []
            bots[bot_name]['attacks'][current]['pre_shell_command_outputs'] << pre_output
            current = check_output_conditions(bot_name, bots, current, pre_output, m)
          end

          # use bot-wide method for obtaining shell, unless specified per-attack
          if bots[bot_name]['attacks'][current].key?('get_shell')
            shell_cmd = bots[bot_name]['attacks'][current]['get_shell'].to_s.clone
          else
            shell_cmd = bots[bot_name]['get_shell'].clone
          end

          if shell_cmd != 'false'
            # substitute special variables
            shell_cmd.gsub!(/{{chat_ip_address}}/, m.user.host.to_s)
            # add a ; to ensure it is run via bash
            shell_cmd << ';'
            Print.debug shell_cmd

            got_shell = false
            Open3.popen2e(shell_cmd) do |stdin, stdout_err, wait_thr|
              begin
                Timeout.timeout(240) do # timeout 240 sec, 4mins to get root
                  # check whether we have shell by echoing "shelltest"
                  lines = ''
                  i = 0
                  while i < 60 and not got_shell # retry for a while
                    i += 1
                    Print.debug i.to_s
                    stdin.puts "echo shelltest\n"
                    sleep(5)

                    # non-blocking read from buffer
                    begin
                      while ch = stdout_err.read_nonblock(1)
                        lines << ch
                      end
                    rescue # continue consuming until input blocks
                    end
                    bots[bot_name]['attacks'][current]['get_shell_command_output'] = lines

                    Print.debug lines
                    if lines =~ /shelltest/i
                      got_shell = true
                      Print.debug 'Got shell!'
                    else
                      Print.debug 'Still trying to get shell...'
                      m.reply '...'
                    end
                  end
                  Print.debug got_shell.to_s
                end
              rescue Timeout::Error
                got_shell = false
                m.reply 'Took too long...'
              rescue
                got_shell = false
              end

              if got_shell
                m.reply bots[bot_name]['messages']['got_shell'].sample

                post_cmd = bots[bot_name]['attacks'][current]['post_command']
                if post_cmd
                  Print.debug post_cmd
                  post_cmd.gsub!(/{{chat_ip_address}}/, m.user.host.to_s)
                  stdin.puts "#{post_cmd}\n"
                end

                sleep(3)
                # non-blocking read from buffer
                post_lines = ''
                begin
                  while ch = stdout_err.read_nonblock(1)
                    post_lines << ch
                  end
                rescue # continue consuming until input blocks
                end
                begin
                  Timeout.timeout(15) do # timeout 15 sec
                    stdin.close # no more input, end the program
                    post_lines << stdout_err.read.chomp()
                  end
                rescue Timeout::Error
                  wait_thr.kill

                  begin
                    while ch = stdout_err.read_nonblock(1)
                      post_lines << ch
                    end
                  rescue # continue consuming until input blocks
                  end

                end

                bots[bot_name]['attacks'][current]['post_command_output'] = post_lines
                bots[bot_name]['attacks'][current]['post_command_outputs'] ||= []
                bots[bot_name]['attacks'][current]['post_command_outputs'] << post_lines

                unless bots[bot_name]['attacks'][current].key?('suppress_command_output_feedback')
                    m.reply "FYI: #{post_lines}"
                end
                Print.debug post_lines

                current = check_output_conditions(bot_name, bots, current, post_lines, m)

              else
                Print.debug("Shell failed...")
                # shell fail message will use the default message, unless specified for the attack
                if bots[bot_name]['attacks'][current].key?('shell_fail_message')
                    m.reply bots[bot_name]['attacks'][current]['shell_fail_message']
                else
                    m.reply bots[bot_name]['messages']['shell_fail_message']
                end
                # under specific situations reveal the error message to the user
                if defined?(lines) && lines =~ /command not found/
                    m.reply "Looks like there is some software missing: #{lines}"
                end
              end

              # ensure any child processes are not left running (without this msfconsole is left running)
              `kill -9 $(ps -o pid --no-headers --ppid #{wait_thr.pid})`
              wait_thr.kill
            end
          end


          if bots[bot_name]['attacks'][current].key?('post_shell')
            post_shell_cmd = bots[bot_name]['attacks'][current]['post_shell'].to_s.clone
            post_shell_cmd.gsub!(/{{chat_ip_address}}/, m.user.host.to_s)

            post_output = `#{post_shell_cmd}`
            unless bots[bot_name]['attacks'][current].key?('suppress_command_output_feedback')
              m.reply "FYI: #{post_output}"
            end
            # bots[bot_name]['attacks'][current]['get_shell_command_output'] = post_output
            current = check_output_conditions(bot_name, bots, current, post_output, m)

          end


          m.reply bots[bot_name]['messages']['repeat'].sample
        end

      end
    end
  end

  bots
end

def start_bots(bots)
  threads = []
  bots.each do |bot_name, bot|
    threads << Thread.new {
      Print.std "Starting bot: #{bot_name}\n"
      bot['bot'].start
    }
  end
  ThreadsWait.all_waits(threads)
end

def usage
  Print.std 'ruby hackerbot.rb [--irc-server host] [--ollama-host host] [--ollama-port port] [--ollama-model model]'
end

# -- main --

Print.std '~'*47
Print.std ' '*19 + 'Hackerbot'
Print.std '~'*47

irc_server_ip_address = 'localhost'

# Get command line arguments
opts = GetoptLong.new(
    [ '--help', '-h', GetoptLong::NO_ARGUMENT ],
    [ '--irc-server', '-i', GetoptLong::REQUIRED_ARGUMENT ],
    [ '--ollama-host', '-o', GetoptLong::REQUIRED_ARGUMENT ],
    [ '--ollama-port', '-p', GetoptLong::REQUIRED_ARGUMENT ],
    [ '--ollama-model', '-m', GetoptLong::REQUIRED_ARGUMENT ],
)

# process option arguments
opts.each do |opt, arg|
  case opt
    # Main options
    when '--help'
      usage
    when '--irc-server'
      irc_server_ip_address = arg;
    when '--ollama-host'
      ollama_host = arg;
    when '--ollama-port'
      ollama_port = arg.to_i;
    when '--ollama-model'
      ollama_model = arg;
    else
      Print.err "Argument not valid: #{arg}"
      usage
      exit
  end
end

if __FILE__ == $0
  bots = read_bots(irc_server_ip_address)
  start_bots(bots)
end
