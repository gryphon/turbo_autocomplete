require "turbo_autocomplete/version"
require "turbo_autocomplete/engine"
require "turbo_autocomplete/configuration"

module TurboAutocomplete
  def self.configuration
    @configuration ||= Configuration.new
  end
  
  def self.configure(&block)
    yield(configuration)
  end
end
