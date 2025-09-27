require 'nokogiri'
require 'nori'
require './print.rb'
require './llm_client_factory.rb'
require './rag_cag_manager.rb'

class BotManager
  def initialize(irc_server_ip_address, llm_provider = 'ollama', ollama_host = 'localhost', ollama_port = 11434, ollama_model = 'gemma3:1b', openai_api_key = nil, vllm_host = 'localhost', vllm_port = 8000, sglang_host = 'localhost', sglang_port = 30000, enable_rag_cag = false, rag_cag_config = {})
    @irc_server_ip_address = irc_server_ip_address
    @llm_provider = llm_provider
    @ollama_host = ollama_host
    @ollama_port = ollama_port
    @ollama_model = ollama_model
    @openai_api_key = openai_api_key
    @vllm_host = vllm_host
    @vllm_port = vllm_port
    @sglang_host = sglang_host
    @sglang_port = sglang_port
    @bots = {}
    @user_chat_histories = Hash.new { |h, k| h[k] = {} } # {bot_name => {user_id => [history]}}
    @max_history_length = 10
    @enable_rag_cag = enable_rag_cag
    @rag_cag_config = rag_cag_config
    @rag_cag_manager = nil

    # Set default offline mode and independent RAG/CAG settings
    @rag_cag_config[:offline_mode] ||= 'auto'  # Default to auto-detect
    @rag_cag_config[:enable_rag] = rag_cag_config.fetch(:enable_rag, true)  # Default to both enabled
    @rag_cag_config[:enable_cag] = rag_cag_config.fetch(:enable_cag, true)  # Default to both enabled

    # Initialize RAG + CAG manager if enabled
    if @enable_rag_cag
      initialize_rag_cag_manager
    end
  end

  def initialize_rag_cag_manager
    Print.info "Initializing RAG + CAG Manager..."

    # Load offline configuration to determine defaults
    require './rag_cag_offline_config'
    offline_config_manager = OfflineConfigurationManager.new

    # Determine if we should use offline mode
    use_offline = case @rag_cag_config[:offline_mode]
                  when 'offline'
                    true
                  when 'online'
                    false
                  else # 'auto'
                    offline_config_manager.detect_connectivity == :offline
                  end

    Print.info "Using #{use_offline ? 'offline' : 'online'} mode for RAG + CAG systems"

    # Default RAG configuration with offline as default
    rag_config = if use_offline
      {
        vector_db: {
          provider: 'chromadb_offline',
          storage_path: './knowledge_bases/offline/vector_db',
          persist_embeddings: true,
          compression_enabled: true
        },
        embedding_service: {
          provider: 'ollama_offline',
          model: 'nomic-embed-text',
          cache_embeddings: true,
          cache_path: './cache/embeddings',
          fallback_to_random: true
        },
        rag_settings: {
          max_results: 5,
          similarity_threshold: 0.7,
          enable_caching: true
        }
      }
    else
      {
        vector_db: {
          provider: 'chromadb',
          host: 'localhost',
          port: 8000
        },
        embedding_service: {
          provider: 'ollama',
          host: @ollama_host,
          port: @ollama_port,
          model: 'nomic-embed-text'
        },
        rag_settings: {
          max_results: 5,
          similarity_threshold: 0.7,
          enable_caching: true
        }
      }
    end

    # Default CAG configuration with offline as default
    cag_config = if use_offline
      {
        knowledge_graph: {
          provider: 'in_memory_offline',
          storage_path: './knowledge_bases/offline/graph',
          persist_graph: true,
          load_from_file: true,
          compression_enabled: true
        },
        entity_extractor: {
          provider: 'rule_based_offline',
          cache_entities: true
        },
        cag_settings: {
          max_context_depth: 2,
          max_context_nodes: 20,
          enable_caching: true
        }
      }
    else
      {
        knowledge_graph: {
          provider: 'in_memory'
        },
        entity_extractor: {
          provider: 'rule_based'
        },
        cag_settings: {
          max_context_depth: 2,
          max_context_nodes: 20,
          enable_caching: true
        }
      }
    end

    # Override with user-provided configuration
    rag_config.deep_merge!(@rag_cag_config[:rag]) if @rag_cag_config[:rag]
    cag_config.deep_merge!(@rag_cag_config[:cag]) if @rag_cag_config[:cag]

    unified_config = {
      enable_rag: @rag_cag_config[:enable_rag],
      enable_cag: @rag_cag_config[:enable_cag],
      rag_weight: @rag_cag_config.fetch(:rag_weight, 0.6),
      cag_weight: @rag_cag_config.fetch(:cag_weight, 0.4),
      max_context_length: @rag_cag_config.fetch(:max_context_length, 4000),
      enable_caching: @rag_cag_config.fetch(:enable_caching, true),
      auto_initialization: @rag_cag_config.fetch(:auto_initialization, true)
    }

    @rag_cag_manager = RAGCAGManager.new(rag_config, cag_config, unified_config)

    unless @rag_cag_manager.setup
      Print.err "Failed to initialize RAG + CAG Manager"
      @rag_cag_manager = nil
    end
  end

  def add_to_history(bot_name, user_id, user_message, assistant_response)
    @user_chat_histories[bot_name][user_id] ||= []
    @user_chat_histories[bot_name][user_id] << { user: user_message, assistant: assistant_response }
    if @user_chat_histories[bot_name][user_id].length > @max_history_length
      @user_chat_histories[bot_name][user_id] = @user_chat_histories[bot_name][user_id].last(@max_history_length)
    end
  end

  def get_chat_context(bot_name, user_id)
    history = @user_chat_histories[bot_name][user_id] || []
    return '' if history.empty?
    context_parts = history.map do |exchange|
      "User: #{exchange[:user]}\nAssistant: #{exchange[:assistant]}"
    end
    context_parts.join("\n\n")
  end

  def clear_user_history(bot_name, user_id)
    @user_chat_histories[bot_name].delete(user_id)
  end

  def get_enhanced_context(bot_name, user_message)
    return nil unless @enable_rag_cag && @rag_cag_manager

    # Check if bot has specific RAG + CAG configuration
    rag_cag_enabled = @bots.dig(bot_name, 'rag_cag_enabled')
    return nil if rag_cag_enabled == false

    # Get bot-specific RAG and CAG settings
    rag_enabled = @bots.dig(bot_name, 'rag_enabled')
    cag_enabled = @bots.dig(bot_name, 'cag_enabled')

    # If neither RAG nor CAG is enabled for this bot, return nil
    return nil if rag_enabled == false && cag_enabled == false

    # Get bot-specific context preferences
    context_options = {}
    if @bots.dig(bot_name, 'rag_cag_config')
      context_options = {
        max_rag_results: @bots.dig(bot_name, 'rag_cag_config', 'max_rag_results') || 5,
        max_cag_depth: @bots.dig(bot_name, 'rag_cag_config', 'max_cag_depth') || 2,
        max_cag_nodes: @bots.dig(bot_name, 'rag_cag_config', 'max_cag_nodes') || 10,
        include_rag_context: rag_enabled != false && (@bots.dig(bot_name, 'rag_cag_config', 'include_rag_context') != false),
        include_cag_context: cag_enabled != false && (@bots.dig(bot_name, 'rag_cag_config', 'include_cag_context') != false),
        custom_collection: @bots.dig(bot_name, 'rag_cag_config', 'collection_name')
      }
    else
      # Use global settings if no bot-specific config
      context_options = {
        max_rag_results: 5,
        max_cag_depth: 2,
        max_cag_nodes: 10,
        include_rag_context: rag_enabled != false,
        include_cag_context: cag_enabled != false,
        custom_collection: nil
      }
    end

    # Get enhanced context from RAG + CAG manager
    enhanced_context = @rag_cag_manager.get_enhanced_context(user_message, context_options)
    Print.debug "Enhanced context length: #{enhanced_context&.length || 0} characters"
    enhanced_context
  end

  def extract_entities_from_message(bot_name, user_message)
    return nil unless @enable_rag_cag && @rag_cag_manager

    # Check if bot has entity extraction enabled
    entity_extraction_enabled = @bots.dig(bot_name, 'entity_extraction_enabled')
    return nil if entity_extraction_enabled == false

    # Check if CAG is enabled for this bot (entity extraction requires CAG)
    cag_enabled = @bots.dig(bot_name, 'cag_enabled')
    return nil if cag_enabled == false

    # Get bot-specific entity types
    entity_types = @bots.dig(bot_name, 'entity_types') || ['ip_address', 'url', 'hash', 'filename']

    # Extract entities
    entities = @rag_cag_manager.extract_entities(user_message, entity_types)
    Print.debug "Extracted #{entities&.length || 0} entities from message"
    entities
  end

  def read_bots
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

      # remove xml namespaces for ease of processing
      doc.remove_namespaces!

      doc.xpath('/hackerbot').each_with_index do |hackerbot|
        bot_name = hackerbot.at_xpath('name').text
        Print.debug bot_name
        @bots[bot_name] = {}

        get_shell = hackerbot.at_xpath('get_shell').text
        Print.debug get_shell
        @bots[bot_name]['get_shell'] = get_shell

        @bots[bot_name]['messages'] = Nori.new.parse(hackerbot.at_xpath('//messages').to_s)['messages']
        Print.debug @bots[bot_name]['messages'].to_s

        @bots[bot_name]['attacks'] = []
        hackerbot.xpath('//attack').each do |attack|
          attack_data = Nori.new.parse(attack.to_s)['attack']
          # Extract system prompt for this attack if specified
          attack_xml = attack.to_s
          if attack_xml.include?('<system_prompt>')
            # Parse the system prompt from the attack XML
            attack_doc = Nokogiri::XML(attack_xml)
            attack_doc.remove_namespaces!
            system_prompt = attack_doc.at_xpath('//system_prompt')&.text
            if system_prompt
              attack_data['system_prompt'] = system_prompt
            end
          end
          @bots[bot_name]['attacks'].push attack_data
        end
        @bots[bot_name]['current_attack'] = 0

        @bots[bot_name]['current_quiz'] = nil

        Print.debug @bots[bot_name]['attacks'].to_s

        # Initialize per-user chat history storage
        @bots[bot_name]['user_chat_history'] = {}

        # Initialize LLM client for this bot based on provider
        # You can customize the model per bot by adding a model attribute to the XML
        provider = hackerbot.at_xpath('llm_provider')&.text || @llm_provider
        model_name = hackerbot.at_xpath('ollama_model')&.text || @ollama_model
        ollama_host_config = hackerbot.at_xpath('ollama_host')&.text || @ollama_host
        ollama_port_config = (hackerbot.at_xpath('ollama_port')&.text || @ollama_port.to_s).to_i
        openai_api_key_config = hackerbot.at_xpath('openai_api_key')&.text || @openai_api_key
        vllm_host_config = hackerbot.at_xpath('vllm_host')&.text || @vllm_host
        vllm_port_config = (hackerbot.at_xpath('vllm_port')&.text || @vllm_port.to_s).to_i
        sglang_host_config = hackerbot.at_xpath('sglang_host')&.text || @sglang_host
        sglang_port_config = (hackerbot.at_xpath('sglang_port')&.text || @sglang_port.to_s).to_i

        system_prompt = hackerbot.at_xpath('system_prompt')&.text || DEFAULT_SYSTEM_PROMPT
        max_tokens = (hackerbot.at_xpath('max_tokens')&.text || DEFAULT_MAX_TOKENS).to_i
        temperature = (hackerbot.at_xpath('model_temperature')&.text || DEFAULT_TEMPERATURE).to_f
        num_thread = (hackerbot.at_xpath('num_thread')&.text || DEFAULT_NUM_THREAD).to_i
        keepalive = (hackerbot.at_xpath('keepalive')&.text || DEFAULT_KEEPALIVE).to_i
        streaming_config = hackerbot.at_xpath('streaming')&.text
        streaming_enabled = streaming_config.nil? ? DEFAULT_STREAMING : (streaming_config.downcase == 'true')

        # Create the appropriate LLM client based on provider
        case provider.downcase
        when 'ollama'
          @bots[bot_name]['chat_ai'] = LLMClientFactory.create_client(
            'ollama',
            host: ollama_host_config,
            port: ollama_port_config,
            model: model_name,
            system_prompt: system_prompt,
            max_tokens: max_tokens,
            temperature: temperature,
            num_thread: num_thread,
            keepalive: keepalive,
            streaming: streaming_enabled
          )
        when 'openai'
          @bots[bot_name]['chat_ai'] = LLMClientFactory.create_client(
            'openai',
            api_key: openai_api_key_config,
            model: model_name,
            system_prompt: system_prompt,
            max_tokens: max_tokens,
            temperature: temperature,
            streaming: streaming_enabled
          )
        when 'vllm'
          @bots[bot_name]['chat_ai'] = LLMClientFactory.create_client(
            'vllm',
            host: vllm_host_config,
            port: vllm_port_config,
            model: model_name,
            system_prompt: system_prompt,
            max_tokens: max_tokens,
            temperature: temperature,
            streaming: streaming_enabled
          )
        when 'sglang'
          @bots[bot_name]['chat_ai'] = LLMClientFactory.create_client(
            'sglang',
            host: sglang_host_config,
            port: sglang_port_config,
            model: model_name,
            system_prompt: system_prompt,
            max_tokens: max_tokens,
            temperature: temperature,
            streaming: streaming_enabled
          )
        else
          # Default to Ollama if provider is not recognized
          Print.err "Unknown LLM provider '#{provider}', defaulting to Ollama"
          @bots[bot_name]['chat_ai'] = LLMClientFactory.create_client(
            'ollama',
            host: ollama_host_config,
            port: ollama_port_config,
            model: model_name,
            system_prompt: system_prompt,
            max_tokens: max_tokens,
            temperature: temperature,
            num_thread: num_thread,
            keepalive: keepalive,
            streaming: streaming_enabled
          )
        end

        # Parse RAG + CAG configuration if enabled
        rag_cag_enabled = hackerbot.at_xpath('rag_cag_enabled')&.text
        @bots[bot_name]['rag_cag_enabled'] = rag_cag_enabled ? (rag_cag_enabled.downcase == 'true') : @enable_rag_cag

        if @bots[bot_name]['rag_cag_enabled']
          # Parse individual RAG and CAG enabling (allowing independent control)
          rag_enabled_node = hackerbot.at_xpath('rag_enabled')&.text
          cag_enabled_node = hackerbot.at_xpath('cag_enabled')&.text

          # Use global settings as defaults, but allow per-bot override
          @bots[bot_name]['rag_enabled'] = if rag_enabled_node
            rag_enabled_node.downcase == 'true'
          else
            @rag_cag_config[:enable_rag]  # Use global setting
          end

          @bots[bot_name]['cag_enabled'] = if cag_enabled_node
            cag_enabled_node.downcase == 'true'
          else
            @rag_cag_config[:enable_cag]  # Use global setting
          end

          # Parse RAG configuration
          rag_config_node = hackerbot.at_xpath('rag_cag_config/rag')
          if rag_config_node
            @bots[bot_name]['rag_cag_config'] ||= {}
            @bots[bot_name]['rag_cag_config']['max_rag_results'] = (rag_config_node.at_xpath('max_rag_results')&.text || '5').to_i
            @bots[bot_name]['rag_cag_config']['include_rag_context'] = !(rag_config_node.at_xpath('include_rag_context')&.text.downcase == 'false')
            @bots[bot_name]['rag_cag_config']['collection_name'] = rag_config_node.at_xpath('collection_name')&.text
          end

          # Parse CAG configuration
          cag_config_node = hackerbot.at_xpath('rag_cag_config/cag')
          if cag_config_node
            @bots[bot_name]['rag_cag_config'] ||= {}
            @bots[bot_name]['rag_cag_config']['max_cag_depth'] = (cag_config_node.at_xpath('max_cag_depth')&.text || '2').to_i
            @bots[bot_name]['rag_cag_config']['max_cag_nodes'] = (cag_config_node.at_xpath('max_cag_nodes')&.text || '10').to_i
            @bots[bot_name]['rag_cag_config']['include_cag_context'] = !(cag_config_node.at_xpath('include_cag_context')&.text.downcase == 'false')
          end

          # Parse entity extraction configuration
          entity_extraction_enabled = hackerbot.at_xpath('entity_extraction_enabled')&.text
          @bots[bot_name]['entity_extraction_enabled'] = entity_extraction_enabled ? (entity_extraction_enabled.downcase == 'true') : true

          # Parse entity types
          entity_types_node = hackerbot.at_xpath('entity_types')
          if entity_types_node
            entity_types = entity_types_node.text.split(',').map(&:strip).reject(&:empty?)
            @bots[bot_name]['entity_types'] = entity_types unless entity_types.empty?
          end
        end

        # Test connection to LLM provider
        unless @bots[bot_name]['chat_ai'].test_connection
          Print.err "Warning: Cannot connect to #{provider} for bot #{bot_name}. Chat responses may not work."
        end

        create_bot(bot_name, system_prompt)
      end
    end

    @bots
  end

  def assemble_prompt(system_prompt, context, chat_context, user_message, enhanced_context = nil)
    if enhanced_context && !enhanced_context.strip.empty?
      # Include RAG + CAG enhanced context
      if context.empty? && chat_context.empty?
        "#{system_prompt}\n\nEnhanced Context:\n#{enhanced_context}\n\nUser: #{user_message}\nAssistant:"
      elsif context.empty?
        "#{system_prompt}\n\nEnhanced Context:\n#{enhanced_context}\n\nChat History:\n#{chat_context}\n\nUser: #{user_message}\nAssistant:"
      elsif chat_context.empty?
        "#{system_prompt}\n\nEnhanced Context:\n#{enhanced_context}\n\nContext: #{context}\n\nUser: #{user_message}\nAssistant:"
      else
        "#{system_prompt}\n\nEnhanced Context:\n#{enhanced_context}\n\nContext: #{context}\n\nChat History:\n#{chat_context}\n\nUser: #{user_message}\nAssistant:"
      end
    else
      # Original prompt assembly without enhanced context
      if context.empty? && chat_context.empty?
        "#{system_prompt}\n\nUser: #{user_message}\nAssistant:"
      elsif context.empty?
        "#{system_prompt}\n\nChat History:\n#{chat_context}\n\nUser: #{user_message}\nAssistant:"
      elsif chat_context.empty?
        "#{system_prompt}\n\nContext: #{context}\n\nUser: #{user_message}\nAssistant:"
      else
        "#{system_prompt}\n\nContext: #{context}\n\nChat History:\n#{chat_context}\n\nUser: #{user_message}\nAssistant:"
      end
    end
  end

  def create_bot(bot_name, system_prompt)
    bots_ref = @bots
    irc_server_ip_address = @irc_server_ip_address
    user_chat_histories = @user_chat_histories
    max_history_length = @max_history_length
    get_chat_context = method(:get_chat_context)
    add_to_history = method(:add_to_history)
    clear_user_history = method(:clear_user_history)
    assemble_prompt = method(:assemble_prompt)

    @bots[bot_name]['bot'] = Cinch::Bot.new do
      configure do |c|
        c.nick = bot_name
        c.server = irc_server_ip_address
        # joins a channel named after the bot, and #bots
        c.channels = ["##{bot_name}", '#bots']
      end

      on :message, /hello/i do |m|
        m.reply "Hello, #{m.user.nick} (#{m.user.host})."
        m.reply bots_ref[bot_name]['messages']['greeting']
        current = bots_ref[bot_name]['current_attack']

        # prompt for the first attack
        if bots_ref[bot_name]['messages'].key?('show_attack_numbers')
          m.reply "** ##{current + 1} **"
        end
        m.reply bots_ref[bot_name]['attacks'][current]['prompt']
        m.reply bots_ref[bot_name]['messages']['say_ready'].sample
      end

      on :message, /help/i do |m|
        m.reply bots_ref[bot_name]['messages']['help']
      end

      on :message, 'next' do |m|
        m.reply bots_ref[bot_name]['messages']['next'].sample

        # is this the last one?
        if bots_ref[bot_name]['current_attack'] < bots_ref[bot_name]['attacks'].length - 1
          bots_ref[bot_name]['current_attack'] += 1
          current = bots_ref[bot_name]['current_attack']
          update_bot_state(bot_name, bots_ref, current)

          # prompt for current hack
          if bots_ref[bot_name]['messages'].key?('show_attack_numbers')
            m.reply "** ##{current + 1} **"
          end
          m.reply bots_ref[bot_name]['attacks'][current]['prompt']
          m.reply bots_ref[bot_name]['messages']['say_ready'].sample
        else
          m.reply bots_ref[bot_name]['messages']['last_attack'].sample
        end
      end

      on :message, /^(goto|attack) [0-9]+$/i do |m|
        m.reply bots_ref[bot_name]['messages']['goto'].sample
        requested_index = m.message.chomp().split[1].to_i - 1

        Print.debug "requested_index = #{requested_index}, bots_ref[bot_name]['attacks'].length = #{bots_ref[bot_name]['attacks'].length}"

        # is this a valid attack number?
        if requested_index < bots_ref[bot_name]['attacks'].length
          update_bot_state(bot_name, bots_ref, requested_index)
          current = bots_ref[bot_name]['current_attack']

          # prompt for current hack
          if bots_ref[bot_name]['messages'].key?('show_attack_numbers')
            m.reply "** ##{current + 1} **"
          end
          m.reply bots_ref[bot_name]['attacks'][current]['prompt']
          m.reply bots_ref[bot_name]['messages']['say_ready'].sample
        else
          m.reply bots_ref[bot_name]['messages']['invalid']
        end
      end

      on :message, /^(the answer is|answer):? .+$/i do |m|
        answer = m.message.chomp().match(/(?:the )?answer(?: is)?:? (.+)$/i)[1]
        current = bots_ref[bot_name]['current_attack']

        quiz = nil
        if bots_ref[bot_name]['attacks'][current].key?('quiz') && bots_ref[bot_name]['attacks'][current]['quiz'].key?('answer')
          quiz = bots_ref[bot_name]['attacks'][current]['quiz']
        end

        if quiz != nil
          correct_answer = quiz['answer'].clone
          if bots_ref[bot_name]['attacks'][current].key?('post_command_output')
            post_outputs = bots_ref[bot_name]['attacks'][current]['post_command_outputs'].map(&:strip).join('|')
            correct_answer.gsub!(/{{post_command_output}}/, post_outputs)
          end
          if bots_ref[bot_name]['attacks'][current].key?('get_shell_command_output')
            shell_outputs = bots_ref[bot_name]['attacks'][current]['shell_command_outputs'].map { |output| output.lines.first.to_s.strip }.join('|')
            correct_answer.gsub!(/{{shell_command_output_first_line}}/, shell_outputs)
          end
          if bots_ref[bot_name]['attacks'][current].key?('pre_shell')
            pre_shell_outputs = bots_ref[bot_name]['attacks'][current]['pre_shell_command_outputs'] || []
            pre_shell_output = pre_shell_outputs.map { |output| output.lines.first.to_s.strip }.join('|')
            correct_answer.gsub!(/{{pre_shell_command_output_first_line}}/, pre_shell_output)
          end
          correct_answer.chomp!
          Print.debug "#{correct_answer}====#{answer}"

          if answer.strip.match?(/^(?:#{correct_answer})$/i)
            m.reply bots_ref[bot_name]['messages']['correct_answer']
            m.reply quiz['correct_answer_response']

            if quiz.key?('trigger_next_attack')
              if bots_ref[bot_name]['current_attack'] < bots_ref[bot_name]['attacks'].length - 1
                bots_ref[bot_name]['current_attack'] += 1
                current = bots_ref[bot_name]['current_attack']
                update_bot_state(bot_name, bots_ref, current)

                sleep(1)
                if bots_ref[bot_name]['messages'].key?('show_attack_numbers')
                  m.reply "** ##{current + 1} **"
                end
                m.reply bots_ref[bot_name]['attacks'][current]['prompt']
                m.reply bots_ref[bot_name]['messages']['say_ready'].sample
              else
                m.reply bots_ref[bot_name]['messages']['last_attack'].sample
              end
            end
          else
            m.reply "#{bots_ref[bot_name]['messages']['incorrect_answer']} (#{answer})"
          end
        else
          m.reply bots_ref[bot_name]['messages']['no_quiz']
        end
      end

      on :message, 'previous' do |m|
        m.reply bots_ref[bot_name]['messages']['previous'].sample

        # is this the last one?
        if bots_ref[bot_name]['current_attack'] > 0
          bots_ref[bot_name]['current_attack'] -= 1
          current = bots_ref[bot_name]['current_attack']
          update_bot_state(bot_name, bots_ref, current)

          # prompt for current hack
          if bots_ref[bot_name]['messages'].key?('show_attack_numbers')
            m.reply "** ##{current + 1} **"
          end
          m.reply bots_ref[bot_name]['attacks'][current]['prompt']
          m.reply bots_ref[bot_name]['messages']['say_ready'].sample
        else
          m.reply bots_ref[bot_name]['messages']['first_attack'].sample
        end
      end

      on :message, 'list' do |m|
        bots_ref[bot_name]['attacks'].each_with_index {|val, index|
          uptohere = ''
          if index == bots_ref[bot_name]['current_attack']
            uptohere = '--> '
          end

          m.reply "#{uptohere}attack #{index+1}: #{val['prompt']}"
        }
      end

      on :message, 'clear_history' do |m|
        user_id = m.user.nick
        clear_user_history.call(bot_name, user_id)
        m.reply "Chat history cleared for #{user_id}."
      end

      on :message, 'show_history' do |m|
        user_id = m.user.nick
        chat_context = get_chat_context.call(bot_name, user_id)
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
        if m.message !~ /hello|help|next|previous|ready|list|clear_history|show_history|^(goto|attack) [0-9]|(the answer is|answer)/
          begin
            user_id = m.user.nick
            current_attack = bots_ref[bot_name]['current_attack']
            attack_context = ''
            current_system_prompt = system_prompt

            if current_attack < bots_ref[bot_name]['attacks'].length
              attack_context = "Current attack (#{current_attack + 1}): #{bots_ref[bot_name]['attacks'][current_attack]['prompt']}"
              # Use attack-specific system prompt if available
              if bots_ref[bot_name]['attacks'][current_attack].key?('system_prompt')
                current_system_prompt = bots_ref[bot_name]['attacks'][current_attack]['system_prompt']
                # Update the OllamaClient's system prompt for this attack
                bots_ref[bot_name]['chat_ai'].update_system_prompt(current_system_prompt)
              end
            end
            chat_context = get_chat_context.call(bot_name, user_id)

            # Get RAG + CAG enhanced context if enabled
            enhanced_context = nil
            if bots_ref[bot_name]['rag_cag_enabled'] != false
              enhanced_context = get_enhanced_context(bot_name, m.message)
            end

            prompt = assemble_prompt.call(current_system_prompt, attack_context, chat_context, m.message, enhanced_context)
            if bots_ref[bot_name]['chat_ai'].instance_variable_get(:@streaming)
              accumulated_text = ''
              stream_callback = Proc.new do |chunk|
                accumulated_text << chunk
                if accumulated_text.include?("\n")
                  lines = accumulated_text.split("\n", -1)
                  lines[0...-1].each do |complete_line|
                    if !complete_line.strip.empty?
                      m.reply complete_line.strip
                    end
                  end
                  accumulated_text = lines.last
                end
              end
              reaction = bots_ref[bot_name]['chat_ai'].generate_response(prompt, stream_callback)
              if !accumulated_text.strip.empty?
                m.reply accumulated_text.strip
              end
              if reaction && !reaction.empty?
                add_to_history.call(bot_name, user_id, m.message, reaction)
              elsif m.message.include?('?')
                m.reply bots_ref[bot_name]['messages']['non_answer']
              end
            else
              reaction = bots_ref[bot_name]['chat_ai'].generate_response(prompt)
              if reaction && !reaction.empty?
                m.reply reaction
                add_to_history.call(bot_name, user_id, m.message, reaction)
              elsif m.message.include?('?')
                m.reply bots_ref[bot_name]['messages']['non_answer']
              end
            end
          rescue Exception => e
            puts e.message
            puts e.backtrace.inspect
            if m.message.include?('?')
              m.reply bots_ref[bot_name]['messages']['non_answer']
            end
          end
        end
      end

      on :message, 'ready' do |m|
        m.reply bots_ref[bot_name]['messages']['getting_shell'].sample
        current = bots_ref[bot_name]['current_attack']

        if bots_ref[bot_name]['attacks'][current].key?('pre_shell')
          pre_shell_cmd = bots_ref[bot_name]['attacks'][current]['pre_shell'].to_s.clone
          pre_shell_cmd.gsub!(/{{chat_ip_address}}/, m.user.host.to_s)

          pre_output = `#{pre_shell_cmd}`
          unless bots_ref[bot_name]['attacks'][current].key?('suppress_command_output_feedback')
            m.reply "FYI: #{pre_output}"
          end
          bots_ref[bot_name]['attacks'][current]['pre_shell_command_outputs'] ||= []
          bots_ref[bot_name]['attacks'][current]['pre_shell_command_outputs'] << pre_output
          current = check_output_conditions(bot_name, bots_ref, current, pre_output, m)
        end

        # use bot-wide method for obtaining shell, unless specified per-attack
        if bots_ref[bot_name]['attacks'][current].key?('get_shell')
          shell_cmd = bots_ref[bot_name]['attacks'][current]['get_shell'].to_s.clone
        else
          shell_cmd = bots_ref[bot_name]['get_shell'].clone
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
                  bots_ref[bot_name]['attacks'][current]['get_shell_command_output'] = lines

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
              m.reply bots_ref[bot_name]['messages']['got_shell'].sample

              post_cmd = bots_ref[bot_name]['attacks'][current]['post_command']
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

              bots_ref[bot_name]['attacks'][current]['post_command_output'] = post_lines
              bots_ref[bot_name]['attacks'][current]['post_command_outputs'] ||= []
              bots_ref[bot_name]['attacks'][current]['post_command_outputs'] << post_lines

              unless bots_ref[bot_name]['attacks'][current].key?('suppress_command_output_feedback')
                  m.reply "FYI: #{post_lines}"
              end
              Print.debug post_lines

              current = check_output_conditions(bot_name, bots_ref, current, post_lines, m)
            else
              Print.debug("Shell failed...")
              # shell fail message will use the default message, unless specified for the attack
              if bots_ref[bot_name]['attacks'][current].key?('shell_fail_message')
                  m.reply bots_ref[bot_name]['attacks'][current]['shell_fail_message']
              else
                  m.reply bots_ref[bot_name]['messages']['shell_fail_message']
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

        if bots_ref[bot_name]['attacks'][current].key?('post_shell')
          post_shell_cmd = bots_ref[bot_name]['attacks'][current]['post_shell'].to_s.clone
          post_shell_cmd.gsub!(/{{chat_ip_address}}/, m.user.host.to_s)

          post_output = `#{post_shell_cmd}`
          unless bots_ref[bot_name]['attacks'][current].key?('suppress_command_output_feedback')
            m.reply "FYI: #{post_output}"
          end
          # bots_ref[bot_name]['attacks'][current]['get_shell_command_output'] = post_output
          current = check_output_conditions(bot_name, bots_ref, current, post_output, m)
        end

        m.reply bots_ref[bot_name]['messages']['repeat'].sample
      end
    end
  end

  def start_bots
    threads = []
    @bots.each do |bot_name, bot|
      threads << Thread.new {
        Print.std "Starting bot: #{bot_name}\n"
        bot['bot'].start
      }
    end
    ThreadsWait.all_waits(threads)
  end
end

# Helper functions that need to be accessible to the bot instances
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
