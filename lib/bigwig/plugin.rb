module BigWig
  class Plugin
    # Each plugin should override Plugin::method and return the name of the command that 
    def self.method
      raise "Plugins must override Plugin::method"
    end

    def self.register
      { self.method => self }
    end
    
    def self.call(task_id, args)
      BigWig.logger.warn "NotImplemented: Called #{self} with #{args} for task #{task_id}"
    end
  end
end