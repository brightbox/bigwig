require 'warren'
require 'warren/adapters/bunny_adapter'
require 'daemons'
require 'optparse'
require 'ostruct'
require 'benchmark'
require 'timeout'

module BigWig
  class Pinger
    attr_reader :config
    attr_reader :options
    
    def initialize(command_line)
      load_options_from command_line
    end
    
    def run
      BigWig::logger.info("Starting bigwig pinger...")
      @config = YAML.load(File.open(@options.config))
      BigWig::connect_using @config

      begin
        Timeout::timeout(@options.timeout) do
          begin
            Warren::Queue.publish :default, :method => 'ping'
          rescue Exception => ex
            BigWig::logger.error("...ping failed with #{ex}")
            exit 2
          end
        end
      rescue Timeout::Error => te
        BigWig::logger.error("...ping timed out: #{te}")
        exit 1
      end

      BigWig::logger.info("...bigwig pinger finished")
      exit 0
    end
    
  protected
    def load_options_from command_line
      @options = OpenStruct.new(:config => File.expand_path('./bigwig.yml'), :timeout => 5) 
      opts = OptionParser.new do |opts|
        opts.banner = "Usage: #{File.basename($0)} [options]"
        opts.on('-h', '--help', 'Show this message') do
          puts opts
          exit 1
        end
        opts.on('-c', '--config=file', 'Path to the config file; if not supplied then bigwig looks for bigwig.yml in the current folder') do |conf|
          @options.config = conf
        end
        opts.on('-t', '--timeout=value', 'Timeout value in seconds') do | conf | 
          @options.timeout = conf.to_i
        end 
      end
      @args = opts.parse!(command_line)
    end
  end
end