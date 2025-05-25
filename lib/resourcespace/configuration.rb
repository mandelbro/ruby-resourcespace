# frozen_string_literal: true

module ResourceSpace
  # Configuration class for ResourceSpace client
  #
  # @example
  #   config = ResourceSpace::Configuration.new
  #   config.url = "https://your-resourcespace.com/api/"
  #   config.user = "your_username"
  #   config.private_key = "your_private_key"
  class Configuration
    # @return [String] the ResourceSpace API URL (must end with /api/)
    attr_accessor :url

    # @return [String] the ResourceSpace username
    attr_accessor :user

    # @return [String] the private API key for the user
    attr_accessor :private_key

    # @return [Integer] request timeout in seconds (default: 30)
    attr_accessor :timeout

    # @return [Integer] number of retry attempts for failed requests (default: 3)
    attr_accessor :retries

    # @return [String] user agent string for requests
    attr_accessor :user_agent

    # @return [Boolean] whether to verify SSL certificates (default: true)
    attr_accessor :verify_ssl

    # @return [String] authentication mode ('userkey', 'sessionkey', or 'native')
    attr_accessor :auth_mode

    # @return [Hash] default headers to include with all requests
    attr_accessor :default_headers

    # @return [Boolean] whether to log API requests and responses (default: false)
    attr_accessor :debug

    # @return [Logger] logger instance for debugging
    attr_accessor :logger

    # Initialize a new configuration with default values
    def initialize
      @url = nil
      @user = nil
      @private_key = nil
      @timeout = 30
      @retries = 3
      @user_agent = "ResourceSpace Ruby Client #{ResourceSpace::VERSION}"
      @verify_ssl = true
      @auth_mode = 'userkey'
      @default_headers = {}
      @debug = false
      @logger = nil
    end

    # Validate the configuration
    #
    # @raise [ConfigurationError] if configuration is invalid
    # @return [Boolean] true if configuration is valid
    def validate!
      errors = []

      errors << 'URL is required' if url.nil? || url.empty?
      errors << 'URL must end with /api/' if url && !url.end_with?('/api/')
      errors << 'User is required' if user.nil? || user.empty?
      errors << 'Private key is required' if private_key.nil? || private_key.empty?
      errors << 'Timeout must be positive' if timeout && timeout <= 0
      errors << 'Retries must be non-negative' if retries&.negative?
      errors << 'Auth mode must be userkey, sessionkey, or native' unless %w[userkey sessionkey
                                                                             native].include?(auth_mode)

      raise ConfigurationError, "Configuration errors: #{errors.join(', ')}" unless errors.empty?

      true
    end

    # Check if configuration is valid without raising an error
    #
    # @return [Boolean] true if configuration is valid
    def valid?
      validate!
      true
    rescue ConfigurationError
      false
    end

    # Convert configuration to a hash
    #
    # @return [Hash] configuration as a hash
    def to_h
      {
        url: url,
        user: user,
        private_key: private_key ? '[REDACTED]' : nil,
        timeout: timeout,
        retries: retries,
        user_agent: user_agent,
        verify_ssl: verify_ssl,
        auth_mode: auth_mode,
        default_headers: default_headers,
        debug: debug
      }
    end

    # Create a duplicate of this configuration
    #
    # @return [Configuration] a new configuration with the same values
    def dup
      new_config = Configuration.new
      new_config.url = url
      new_config.user = user
      new_config.private_key = private_key
      new_config.timeout = timeout
      new_config.retries = retries
      new_config.user_agent = user_agent
      new_config.verify_ssl = verify_ssl
      new_config.auth_mode = auth_mode
      new_config.default_headers = default_headers.dup
      new_config.debug = debug
      new_config.logger = logger
      new_config
    end
  end
end
