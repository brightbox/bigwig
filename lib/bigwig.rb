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
end

Dir["#{BIGWIG_ROOT}/lib/bigwig/*.rb"].each {|r| require r }
Dir["#{BIGWIG_ROOT}/lib/bigwig/internal_plugins/*.rb"].each {|r| require r }
