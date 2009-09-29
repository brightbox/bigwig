module BigWig
  require 'benchmark'
  # Dispatches jobs as they are received from the queue to the relevant plugin.  
  # Each message on the queue is expected to take a form similar to: 
  #   {
  #     :method => 'my_method_name', 
  #     :id => 'optional arbitrary task identifier', 
  #     :data => { :hash => :of, :relevant => :data }
  #   }
  # The dispatch message asks for the Plugin that knows how to deal with the given method name and invokes it with the relevant id and data
  class Job
    
    # Dispatch the given message to the correct plugin
    def self.dispatch(msg)
      new(msg).run
    end
    
    def initialize(msg)
      @method = msg[:method]
      @task_id = msg[:id]
      @data = msg[:data] || {}
    end
    
    # Invoke the plugin with the given data and task id
    def run
      jobid = @task_id || rand(0xfffffff).to_s(16).upcase
      BigWig::logger.info("Received #{@method} (job #{jobid}) with #{@data.inspect}")
      
      result = nil
      benchmark = begin
        Benchmark.measure do
          result = plugin_for(@method).call(@task_id, @data) 
        end
      rescue StandardError => e
        BigWig::logger.error("Bigwig Job id #{jobid} failed with exception #{e}: #{e.message}")
        raise e
      end

      BigWig::logger.info("Bigwig Job id #{jobid} completed in #{benchmark.real.round} seconds")
      return result
    end
    
  private
    def plugin_for(method)
      BigWig::Plugins.plugin_for(method)
    end
  end
end
