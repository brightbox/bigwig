# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{bigwig}
  s.version = "0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.2") if s.respond_to? :required_rubygems_version=
  s.authors = ["David Smalley, Caius Durling, Rahoul Baruah"]
  s.date = %q{2009-09-29}
  s.default_executable = %q{bigwig}
  s.description = %q{A daemon that listens to an AMQP queue and responds to messages by invoking commands from a set of plugins}
  s.email = %q{}
  s.executables = ["bigwig"]
  s.extra_rdoc_files = ["CHANGELOG", "LICENSE", "README", "bin/bigwig", "lib/bigwig.rb", "lib/bigwig/internal_plugins/ping_plugin.rb", "lib/bigwig/job.rb", "lib/bigwig/plugin.rb", "lib/bigwig/plugins.rb", "lib/bigwig/runner.rb"]
  s.files = ["CHANGELOG", "LICENSE", "README", "Rakefile", "bigwig.output", "bigwig.yml", "bigwig.yml.example", "bin/bigwig", "lib/bigwig.rb", "lib/bigwig/internal_plugins/ping_plugin.rb", "lib/bigwig/job.rb", "lib/bigwig/plugin.rb", "lib/bigwig/plugins.rb", "lib/bigwig/runner.rb", "Manifest", "bigwig.gemspec"]
  s.homepage = %q{http://www.brightbox.co.uk/}
  s.post_install_message = %q{Welcome to bigwig.  Please set up a configuration file and a plugins folder before starting bigwig...}
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "Bigwig", "--main", "README"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{bigwig}
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{A daemon that listens to an AMQP queue and responds to messages by invoking commands from a set of plugins}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<brightbox-warren>, [">= 0.9.0"])
      s.add_runtime_dependency(%q<daemons>, [">= 1.0.10"])
    else
      s.add_dependency(%q<brightbox-warren>, [">= 0.9.0"])
      s.add_dependency(%q<daemons>, [">= 1.0.10"])
    end
  else
    s.add_dependency(%q<brightbox-warren>, [">= 0.9.0"])
    s.add_dependency(%q<daemons>, [">= 1.0.10"])
  end
end
