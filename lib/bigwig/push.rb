require 'warren'
require 'warren/adapters/bunny_adapter'
require 'daemons'
require 'optparse'
require 'benchmark'
require 'timeout'

module BigWig
  # pushes a message onto the queue
  # USAGE:
  #     push = BigWig::Push.new :config => '/path/to/config/file', :timeout => 5
  # By default, it uses bigwig.yml in the current directory and a timeout of 5 seconds
  # The configuration file is expected to have the same structure as the BigWig daemon's file (without the plugins folder)
  class Push
    attr_reader :config
    attr_reader :options

    # Create a new BigWig::Push
    # Options: 
    #     :config => '/path/to/config/file'
    #     :timeout => 5    
    #
    def initialize(overrides = {})
      @options = {
        :config => File.expand_path('./bigwig.yml'), 
        :timeout => 5
      }.merge(overrides)
    end
    
    # Push a message on to the queue, passing in a message name, plus an optional data hash, an optional task id and an optional queue name
    # 
    def message method, data = {}, task_id = nil, queue = :default
      BigWig::logger.info("Pushing #{method} on to #{queue}")
      @config = YAML.load(File.open(@options[:config]))
      BigWig::connect_using @config

      begin
        Timeout::timeout(@options[:timeout]) do
          begin
            Warren::Queue.publish queue, :method => method, :id => task_id, :data => data
          rescue Exception => ex
            BigWig::logger.error("...push failed with #{ex}")
            exit 1
          end
        end
      rescue Timeout::Error => te
        BigWig::logger.error("...push timed out: #{te}")
        exit 1
      end

      BigWig::logger.info("...bigwig push finished")
      exit 0
    end
    
    # Helper method so that calling scripts don't need to parse the Push parameters themselves
    #
    # USAGE: 
    #     options = BigWig::Push.load_options_from ARGV
    #     BigWig::Push.new(options).message 'whatever'
    #
    # If this is being called from a wrapper script (such as bin/bigwig-push) that needs its own parameters you can pass a block to append your own details
    #
    #     options = BigWig::Push.load_options_from(ARGV) do | parser, options | 
    #       parser.on('--xxx', 'Push it good') do 
    #         options[:push_it_good] = :push_it_real_good
    #       end 
    #     end
    #
    def self.load_options_from command_line
      options = {}
            
      parser = OptionParser.new do | parser |
        parser.banner = "Usage: #{File.basename($0)} [options]"

        parser.on('-h', '--help', 'Show this message') do
          puts parser
          exit 2
        end
        
        parser.on('-c', '--config=file', 'Path to the config file; if not supplied then bigwig looks for bigwig.yml in the current folder') do |conf|
          options[:config] = conf
        end
        
        parser.on('-t', '--timeout=value', 'Timeout value in seconds') do | conf | 
          options[:timeout] = conf.to_i
        end 
        
        yield(parser, options) if block_given?

      end
      parser.parse!(command_line)
      
      return options
    end
  
  end
end