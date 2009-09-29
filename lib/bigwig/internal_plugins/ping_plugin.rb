class PingPlugin < BigWig::Plugin

  def self.method
    "ping"
  end
  
  def self.call(task_id, args)
    BigWig.logger.info "#{Time.now.to_s}: ping received"
  end

end