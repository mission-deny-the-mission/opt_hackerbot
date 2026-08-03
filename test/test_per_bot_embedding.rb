require_relative 'test_helper'

# Tests for per-bot embedding service configuration:
# - <embedding_model>/<embedding_provider>/<embedding_host>/<embedding_port>
#   in the bot XML are parsed into @bots[bot_name]['embedding_config']
# - bot_rag_config reads the parsed per-bot RAG config (rag_cag_config key)
# - embedding_service_config_for derives the correct service per provider
# - bot_rag_manager returns the global manager unless a per-bot override
#   differs from the global embedding service
class TestPerBotEmbedding < BotManagerTest
  def test_embedding_service_config_for_openai
    bot_manager = create_bot_manager(llm_provider: 'openai', openai_base_url: 'http://litellm:4000', openai_api_key: 'k')
    svc = bot_manager.embedding_service_config_for(provider: 'openai', model: 'bge-m3', openai_base_url: 'http://litellm:4000', openai_api_key: 'k')
    assert_equal 'openai', svc[:provider]
    assert_equal 'http://litellm:4000', svc[:base_url]
    assert_equal 'bge-m3', svc[:model]
  end

  def test_embedding_service_config_for_vllm
    bot_manager = create_bot_manager
    svc = bot_manager.embedding_service_config_for(provider: 'vllm', model: 'nomic-embed-text', vllm_host: '10.0.0.5', vllm_port: 8000)
    assert_equal 'openai', svc[:provider]
    assert_equal 'http://10.0.0.5:8000/v1', svc[:base_url]
    assert_equal 'nomic-embed-text', svc[:model]
  end

  def test_embedding_service_config_for_ollama
    bot_manager = create_bot_manager
    svc = bot_manager.embedding_service_config_for(provider: 'ollama', model: 'nomic-embed-text', host: 'localhost', port: 11434)
    assert_equal 'ollama', svc[:provider]
    assert_equal 'localhost', svc[:host]
    assert_equal 11434, svc[:port]
  end

  def test_embedding_service_config_unknown_provider_defaults_to_ollama
    bot_manager = create_bot_manager
    svc = bot_manager.embedding_service_config_for(provider: 'bogus')
    assert_equal 'ollama', svc[:provider]
    assert_equal 'nomic-embed-text', svc[:model]
  end

  def test_read_bots_parses_per_bot_embedding_config
    bot_manager = create_bot_manager
    config = <<~XML
      <hackerbot>
        <name>EmbedBot</name>
        <llm_provider>ollama</llm_provider>
        <ollama_model>gemma3:1b</ollama_model>
        <embedding_model>bge-m3</embedding_model>
        <embedding_provider>openai</embedding_provider>
        <embedding_host>litellm.lab</embedding_host>
        <embedding_port>4000</embedding_port>
        <system_prompt>You are a test bot.</system_prompt>
        <get_shell>bash</get_shell>
        <messages>
          <greeting>Hello</greeting>
          <say_ready>Ready</say_ready>
          <next>Next</next>
          <previous>Prev</previous>
        </messages>
        <attacks>
          <attack>
            <prompt>Test</prompt>
            <quiz>
              <question>Q?</question>
              <answer>A</answer>
            </quiz>
          </attack>
        </attacks>
      </hackerbot>
    XML
    create_temp_config_file(config)
    begin
      Dir.stub(:glob, [@temp_config_path]) do
      bot_manager.read_bots
      end
      bots = bot_manager.instance_variable_get(:@bots)
      emb = bots['EmbedBot']['embedding_config']
      refute_nil emb, 'embedding_config should be parsed'
      assert_equal 'bge-m3', emb['model']
      assert_equal 'openai', emb['provider']
      assert_equal 'litellm.lab', emb['host']
      assert_equal 4000, emb['port']
    ensure
      cleanup_temp_config
    end
  end

  def test_read_bots_embedding_config_only_keeps_explicit_values
    bot_manager = create_bot_manager
    config = <<~XML
      <hackerbot>
        <name>SoloModelBot</name>
        <llm_provider>ollama</llm_provider>
        <ollama_model>gemma3:1b</ollama_model>
        <embedding_model>nomic-embed-text</embedding_model>
        <system_prompt>You are a test bot.</system_prompt>
        <get_shell>bash</get_shell>
        <messages>
          <greeting>Hello</greeting>
          <say_ready>Ready</say_ready>
          <next>Next</next>
          <previous>Prev</previous>
        </messages>
      </hackerbot>
    XML
    create_temp_config_file(config)
    begin
      Dir.stub(:glob, [@temp_config_path]) do
      bot_manager.read_bots
      end
      bots = bot_manager.instance_variable_get(:@bots)
      emb = bots['SoloModelBot']['embedding_config']
      refute_nil emb
      assert_equal 'nomic-embed-text', emb['model']
      assert_nil emb['provider'], 'provider should not be set when not explicit'
      assert_nil emb['host']
    ensure
      cleanup_temp_config
    end
  end

  def test_bot_without_embedding_config_has_no_override
    bot_manager = create_bot_manager
    create_temp_config_file
    begin
      Dir.stub(:glob, [@temp_config_path]) do
      bot_manager.read_bots
      end
      bots = bot_manager.instance_variable_get(:@bots)
      emb = bots['TestBot']['embedding_config']
      assert_empty emb, 'no embedding_config expected when XML has no embedding tags'
    ensure
      cleanup_temp_config
    end
  end

  def test_bot_rag_config_reads_parsed_cag_config
    bot_manager = create_bot_manager
    config = <<~XML
      <hackerbot>
        <name>RagBot</name>
        <llm_provider>ollama</llm_provider>
        <ollama_model>gemma3:1b</ollama_model>
        <rag_enabled>true</rag_enabled>
        <rag_cag_config>
          <rag>
            <max_rag_results>3</max_rag_results>
            <collection_name>bot_special</collection_name>
          </rag>
        </rag_cag_config>
        <system_prompt>You are a test bot.</system_prompt>
        <get_shell>bash</get_shell>
        <messages>
          <greeting>Hello</greeting>
          <say_ready>Ready</say_ready>
          <next>Next</next>
          <previous>Prev</previous>
        </messages>
      </hackerbot>
    XML
    create_temp_config_file(config)
    begin
      Dir.stub(:glob, [@temp_config_path]) do
      bot_manager.read_bots
      end
      cfg = bot_manager.bot_rag_config('RagBot')
      assert_equal 3, cfg['max_rag_results']
      assert_equal 'bot_special', cfg['collection_name']
    ensure
      cleanup_temp_config
    end
  end

  def test_bot_rag_manager_returns_global_without_override
    bot_manager = create_bot_manager
    bot_manager.instance_variable_set(:@enable_rag, true)
    global_mgr = Object.new
    bot_manager.instance_variable_set(:@rag_manager, global_mgr)
    bot_manager.instance_variable_set(:@rag_service_settings, { embedding_service: { provider: 'ollama', model: 'nomic-embed-text' } })
    bot_manager.instance_variable_set(:@bots, { 'TestBot' => {} })
    assert_same global_mgr, bot_manager.bot_rag_manager('TestBot')
  end

  def test_bot_rag_manager_returns_global_when_service_matches
    bot_manager = create_bot_manager
    bot_manager.instance_variable_set(:@enable_rag, true)
    global_mgr = Object.new
    bot_manager.instance_variable_set(:@rag_manager, global_mgr)
    bot_manager.instance_variable_set(:@rag_service_settings, { embedding_service: { provider: 'ollama', model: 'nomic-embed-text', host: 'localhost', port: 11434 } })
    # Same effective service as global -> must not create a second manager
    bot_manager.instance_variable_set(:@bots, { 'TestBot' => { 'embedding_config' => { 'model' => 'nomic-embed-text' } } })
    assert_same global_mgr, bot_manager.bot_rag_manager('TestBot')
  end
end
