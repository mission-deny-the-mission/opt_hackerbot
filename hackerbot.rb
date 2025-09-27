require 'ircinch'
require 'open3'
require 'getoptlong'
require 'thwait'
require './print.rb'
require './bot_manager.rb'

def usage
  Print.std 'ruby hackerbot.rb [OPTIONS]'
  Print.std ''
  Print.std 'Options:'
  Print.std '  --irc-server, -i HOST          IRC server IP address (default: localhost)'
  Print.std '  --llm-provider, -l PROVIDER    LLM provider: ollama, openai, vllm, sglang (default: ollama)'
  Print.std '  --ollama-host, -o HOST         Ollama server host (default: localhost)'
  Print.std '  --ollama-port, -p PORT         Ollama server port (default: 11434)'
  Print.std '  --ollama-model, -m MODEL       Ollama model name (default: gemma3:1b)'
  Print.std '  --openai-api-key, -k KEY       OpenAI API key'
  Print.std '  --vllm-host HOST               VLLM server host (default: localhost)'
  Print.std '  --vllm-port PORT               VLLM server port (default: 8000)'
  Print.std '  --sglang-host HOST             SGLang server host (default: localhost)'
  Print.std '  --sglang-port PORT             SGLang server port (default: 30000)'
  Print.std '  --streaming, -s true|false     Enable/disable streaming (default: true)'
  Print.std '  --help, -h                     Show this help message'
end

# -- main --

Print.std '~'*47
Print.std ' '*19 + 'Hackerbot'
Print.std '~'*47

irc_server_ip_address = 'localhost'
llm_provider = 'ollama'  # Default provider
ollama_host = 'localhost'
ollama_port = 11434
ollama_model = 'gemma3:1b'
openai_api_key = nil
vllm_host = 'localhost'
vllm_port = 8000
sglang_host = 'localhost'
sglang_port = 30000

# Get command line arguments
opts = GetoptLong.new(
    [ '--help', '-h', GetoptLong::NO_ARGUMENT ],
    [ '--irc-server', '-i', GetoptLong::REQUIRED_ARGUMENT ],
    [ '--llm-provider', '-l', GetoptLong::REQUIRED_ARGUMENT ],
    [ '--ollama-host', '-o', GetoptLong::REQUIRED_ARGUMENT ],
    [ '--ollama-port', '-p', GetoptLong::REQUIRED_ARGUMENT ],
    [ '--ollama-model', '-m', GetoptLong::REQUIRED_ARGUMENT ],
    [ '--openai-api-key', '-k', GetoptLong::REQUIRED_ARGUMENT ],
    [ '--vllm-host', GetoptLong::REQUIRED_ARGUMENT ],
    [ '--vllm-port', GetoptLong::REQUIRED_ARGUMENT ],
    [ '--sglang-host', GetoptLong::REQUIRED_ARGUMENT ],
    [ '--sglang-port', GetoptLong::REQUIRED_ARGUMENT ],
    [ '--streaming', '-s', GetoptLong::REQUIRED_ARGUMENT ],
)

# process option arguments
opts.each do |opt, arg|
  case opt
    # Main options
    when '--help'
      usage
    when '--help'
      usage
    when '--irc-server'
      irc_server_ip_address = arg;
    when '--llm-provider'
      llm_provider = arg;
    when '--ollama-host'
      ollama_host = arg;
    when '--ollama-port'
      ollama_port = arg.to_i;
    when '--ollama-model'
      ollama_model = arg;
    when '--openai-api-key'
      openai_api_key = arg;
    when '--vllm-host'
      vllm_host = arg;
    when '--vllm-port'
      vllm_port = arg.to_i;
    when '--sglang-host'
      sglang_host = arg;
    when '--sglang-port'
      sglang_port = arg.to_i;
    when '--streaming'
      streaming_arg = arg.downcase
      if streaming_arg == 'true' || streaming_arg == 'false'
        DEFAULT_STREAMING = (streaming_arg == 'true')
      else
        Print.err "Streaming argument must be 'true' or 'false': #{arg}"
        usage
        exit
      end
    else
      Print.err "Argument not valid: #{arg}"
      usage
      exit
  end
end

if __FILE__ == $0
  bot_manager = BotManager.new(irc_server_ip_address, llm_provider, ollama_host, ollama_port, ollama_model, openai_api_key, vllm_host, vllm_port, sglang_host, sglang_port)
  bots = bot_manager.read_bots
  bot_manager.start_bots
end
