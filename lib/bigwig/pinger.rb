module BigWig
  class Pinger
    def initialize command_line
      @push = Push.new command_line
    end
    
    def run
      @push.message 'ping'
    end
  end
end