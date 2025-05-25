# frozen_string_literal: true

require_relative 'resourcespace/version'
require_relative 'resourcespace/client'
require_relative 'resourcespace/configuration'
require_relative 'resourcespace/errors'
require_relative 'resourcespace/resource'
require_relative 'resourcespace/collection'
require_relative 'resourcespace/search'
require_relative 'resourcespace/user'
require_relative 'resourcespace/metadata'

# ResourceSpace Ruby client for interacting with ResourceSpace Digital Asset Management API
#
# @example Basic usage
#   client = ResourceSpace::Client.new(
#     url: "https://your-resourcespace.com/api/",
#     user: "your_username",
#     private_key: "your_private_key"
#   )
#
#   # Search for resources
#   results = client.search.do_search("cat")
#
#   # Upload a file
#   resource = client.resources.create_resource(
#     name: "My Image",
#     file: File.open("path/to/image.jpg")
#   )
#
# @see https://www.resourcespace.com/knowledge-base/api/
module ResourceSpace
  class << self
    # Global configuration for the ResourceSpace gem
    #
    # @return [Configuration] the global configuration instance
    attr_accessor :configuration

    # Configure the ResourceSpace gem globally
    #
    # @yield [Configuration] the configuration instance
    # @return [Configuration] the updated configuration
    #
    # @example
    #   ResourceSpace.configure do |config|
    #     config.url = "https://your-resourcespace.com/api/"
    #     config.user = "your_username"
    #     config.private_key = "your_private_key"
    #     config.timeout = 30
    #   end
    def configure
      self.configuration ||= Configuration.new
      yield(configuration) if block_given?
      configuration
    end

    # Get the current configuration or create a new one
    #
    # @return [Configuration] the configuration instance
    def config
      self.configuration ||= Configuration.new
    end

    # Reset the configuration to defaults
    #
    # @return [Configuration] a new configuration instance
    def reset_config!
      self.configuration = Configuration.new
    end
  end
end
