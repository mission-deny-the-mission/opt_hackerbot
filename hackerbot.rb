require 'ircinch'
require 'open3'
require 'getoptlong'
require 'thwait'
require './print.rb'
require './ollama_client.rb'
require './bot_manager.rb'

def usage
  Print.std 'ruby hackerbot.rb [--irc-server host] [--ollama-host host] [--ollama-port port] [--ollama-model model] [--streaming true|false]'
end

# -- main --

Print.std '~'*47
Print.std ' '*19 + 'Hackerbot'
Print.std '~'*47

irc_server_ip_address = 'localhost'
ollama_host = 'localhost'
ollama_port = 11434
ollama_model = 'gemma3:1b'

# Get command line arguments
opts = GetoptLong.new(
    [ '--help', '-h', GetoptLong::NO_ARGUMENT ],
    [ '--irc-server', '-i', GetoptLong::REQUIRED_ARGUMENT ],
    [ '--ollama-host', '-o', GetoptLong::REQUIRED_ARGUMENT ],
    [ '--ollama-port', '-p', GetoptLong::REQUIRED_ARGUMENT ],
    [ '--ollama-model', '-m', GetoptLong::REQUIRED_ARGUMENT ],
    [ '--streaming', '-s', GetoptLong::REQUIRED_ARGUMENT ],
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
  bot_manager = BotManager.new(irc_server_ip_address, ollama_host, ollama_port, ollama_model)
  bots = bot_manager.read_bots
  bot_manager.start_bots
end
