require 'warren'
require 'warren/adapters/bunny_adapter'
require 'daemons'
require 'optparse'
require 'ostruct'
require 'benchmark'

module BigWig
  class Runner
    attr_reader :args
    attr_reader :options
    attr_reader :config
    
    # start the bigwig process
    # use a default config file of bigwig.yml in the current folder, unless one is provided on the command line
    def initialize(command_line_options)
      load_options_from command_line_options
    end
  
    def run
      Daemons.run_proc('bigwig', :dir => @options.log_folder, :dir_mode => :normal, :log_output => true,  :ARGV => self.args) do |*args|
        @config = YAML.load(File.open(@options.config))
        load_plugins_from @config["plugins_folder"]
        load_init_scripts_from @config["init_folder"]
        begin
          BigWig::logger.info("Starting Bigwig job worker")

          trap_signals
          BigWig::connect_using config

          last_successful_subscription = Time.now
          last_connection_failed = false
          loop do
            message_received = false
            break if $exit 

            begin
              Warren::Queue.subscribe(:default) do |msg|
                BigWig::Job.dispatch(msg)
                message_received = true
              end
              
              last_successful_subscription = Time.now # record the time in case we have a failure next time round
              if last_connection_failed
                BigWig.logger.info('...reconnected successfully')
                last_connection_failed = false
              end
              sleep(0.5) unless message_received # if the queue was empty, go to sleep before checking for the next message
              
            rescue Exception => ex # if there was an error connecting to the queue, wait a bit and then retry TODO: Change this exception
              BigWig::logger.error("Error when subscribing to the queue: #{ex}")
              retry_time = calculate_retry_time_based_upon last_successful_subscription
              sleep(retry_time)
              last_connection_failed = true
            end
            
            break if $exit
          end

          BigWig::logger.info("Bigwig job worker stopped")
        rescue => e
          BigWig::logger.fatal("Exiting due to exception #{e}, #{e.message}")
          exit 1
        end
      end
    end

  private
    def load_options_from command_line_options
      @options = OpenStruct.new(:config => File.expand_path('./bigwig.yml'), :log_folder => File.expand_path('.')) 
      opts = OptionParser.new do |opts|
        opts.banner = "Usage: #{File.basename($0)} [options] start|stop|restart|run"
        opts.on('-h', '--help', 'Show this message') do
          puts opts
          exit 1
        end
        opts.on('-c', '--config=file', 'Path to the config file; if not supplied then bigwig looks for bigwig.yml in the current folder') do |conf|
          @options.config = conf
        end
        opts.on('-l', '--log=folder', 'Path to a folder for the log file; if not supplied then bigwig will write its PID and log to the current folder') do |conf|
          @options.log_folder = conf
        end
      end
      @args = opts.parse!(command_line_options)
    end
    
    def load_plugins_from folder
      BigWig::Plugins.root = folder
      BigWig::Plugins.load_all
    end
    
    def load_init_scripts_from folder
      return unless folder
      BigWig::InitScripts.root = folder
      BigWig::InitScripts.load_all
    end
    
    def trap_signals
      trap('TERM') do
        BigWig::logger.info('Bigwig exiting due to TERM signal')
        $exit = true
      end
      trap('INT') do
        BigWig::logger.info('Bigwig exiting due to INT signal')
        $exit = true
      end
    end
    
    def calculate_retry_time_based_upon last_connection_time
      seconds_since_last_connection = (Time.now - last_connection_time).to_i
      minutes = (seconds_since_last_connection.to_f / 60.0)
      minutes_squared = minutes * minutes
      
      # use a quadratic equation seconds_till_retry = a.x.x + b.x + c
      # where x is the time in minutes since last connection
      scale_down_factor = 0.5 # a in our equation
      scale_movement_factor = 5 # b in our equation
      constant_factor = 20.0 # c in our equation
      
      seconds_till_retry = (minutes_squared * scale_down_factor) + (minutes * scale_movement_factor) + constant_factor
      BigWig::logger.info("#{minutes.to_i} minutes since last successful connection: retrying in #{seconds_till_retry.to_i} seconds...")
      
      return seconds_till_retry.to_i
    end
  end
end
