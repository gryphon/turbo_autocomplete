require_relative "lib/turbo_autocomplete/version"

Gem::Specification.new do |spec|
  spec.name        = "turbo_autocomplete"
  spec.version     = TurboAutocomplete::VERSION
  spec.authors     = [""]
  spec.email       = [""]
  spec.homepage    = "http://github.com/gryphon/turbo_autocomplete"
  spec.summary     = "Turbo-enabled Autocomplete input for Simple Form"
  spec.description = "Turbo-enabled Autocomplete input for Simple Form"
  
  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the "allowed_push_host"
  # to allow pushing to a single host or delete this section to allow pushing to any host.

  spec.metadata["homepage_uri"] = spec.homepage

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 7.0"
  spec.add_dependency "simple_form"
end
