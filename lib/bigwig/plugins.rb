module BigWig
  # loads all the plugins from the BigWig::Plugins.root folder
  class Plugins 
    class << self
      attr_accessor :root
      
      # load all plugins in the BigWig::Plugins.root folder
      def load_all
        register_plugins
      end
      
      # find the plugin with the given name
      def plugin_for(key)
        PLUGINS[key] || BigWig::Plugin
      end
      
    private
      PLUGINS = {} unless defined? PLUGINS

      # list of all known plugin files
      def all_plugins
        Dir["#{Plugins.root}/**/*_plugin.rb"]
      end

      # go through each plugin and register it
      def register_plugins
        all_plugins.each do |plugin|
          BigWig.logger.info "Registering plugin: #{plugin}"
          require plugin
          plugin_class = constantize(camelize(File.basename(plugin, ".rb")))
          PLUGINS.merge!(plugin_class.register)
        end
        # and add the inbuilt Ping plugin
        PLUGINS.merge!(PingPlugin.register)
        PLUGINS.freeze
      end

      # Helper method stolen from Rails :)
      def constantize(camel_cased_word)
        names = camel_cased_word.split('::')
        names.shift if names.empty? || names.first.empty?
        constant = Object
        names.each do |name|
         constant = constant.const_defined?(name) ? constant.const_get(name) : constant.const_missing(name)
        end
        constant
      end
      
      # Helper method stolen from Rails :)
      def camelize(lower_case_and_underscored_word, first_letter_in_uppercase = true)
        if first_letter_in_uppercase
          lower_case_and_underscored_word.to_s.gsub(/\/(.?)/) { "::#{$1.upcase}" }.gsub(/(?:^|_)(.)/) { $1.upcase }
        else
          lower_case_and_underscored_word.first.downcase + camelize(lower_case_and_underscored_word)[1..-1]
        end
      end
    end
  end
end