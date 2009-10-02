require 'rubygems'

BIGWIG_ROOT = File.expand_path(File.join(File.dirname(__FILE__), ".."))

module BigWig
  require 'logger'

  def self.logger
    @logger ||= begin
      l = Logger.new(STDERR)
      l.level = Logger::DEBUG
      l
    end
  end

  def self.logger=(l)
    @logger = l
  end
  
  def self.connect_using config
    env = ENV['WARREN_ENV'] || 'development'
    
    h = {:user => config["user"], :pass => config["password"], :vhost => config["vhost"], :default_queue => config["queue"], :host => config["server"], :logging => config["warren_logging"]}
  
    params = { env => h }
    
    Warren::Queue.logger = BigWig::logger
    Warren::Queue.connection = params
  end
end

Dir["#{BIGWIG_ROOT}/lib/bigwig/*.rb"].each {|r| require r }
Dir["#{BIGWIG_ROOT}/lib/bigwig/internal_plugins/*.rb"].each {|r| require r }
