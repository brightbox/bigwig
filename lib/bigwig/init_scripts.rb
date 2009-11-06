module BigWig
  class InitScripts
    class << self
      attr_accessor :root

      def load_all
        BigWig.logger.info "Loading #{all_scripts.size} init scripts"
        all_scripts.each do |script|
          # Log n load
          BigWig.logger.info "init script: #{script}"
          require script
        end
      end

      protected

      def all_scripts
        Dir["#{self.root}/**/*.rb"]
      end

    end
  end
end
