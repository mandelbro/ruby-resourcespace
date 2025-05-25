# frozen_string_literal: true

require 'faraday'
require 'faraday/multipart'
require 'json'
require 'digest'
require 'uri'

module ResourceSpace
  # Main client class for interacting with ResourceSpace API
  #
  # @example
  #   client = ResourceSpace::Client.new(
  #     url: "https://your-resourcespace.com/api/",
  #     user: "your_username",
  #     private_key: "your_private_key"
  #   )
  class Client
    # @return [Configuration] client configuration
    attr_reader :config

    # @return [Resource] resource management interface
    attr_reader :resources

    # @return [Collection] collection management interface
    attr_reader :collections

    # @return [Search] search interface
    attr_reader :search

    # @return [User] user management interface
    attr_reader :users

    # @return [Metadata] metadata management interface
    attr_reader :metadata

    # Initialize a new ResourceSpace client
    #
    # @param url [String] ResourceSpace API URL
    # @param user [String] ResourceSpace username
    # @param private_key [String] ResourceSpace private API key
    # @param config [Configuration] configuration object
    # @param options [Hash] additional configuration options
    def initialize(url: nil, user: nil, private_key: nil, config: nil, **options)
      @config = config || ResourceSpace.config.dup

      # Set configuration from parameters
      @config.url = url if url
      @config.user = user if user
      @config.private_key = private_key if private_key

      # Apply additional options
      options.each { |key, value| @config.public_send("#{key}=", value) if @config.respond_to?("#{key}=") }

      # Validate configuration
      @config.validate!

      # Initialize API interfaces
      @resources = Resource.new(self)
      @collections = Collection.new(self)
      @search = Search.new(self)
      @users = User.new(self)
      @metadata = Metadata.new(self)
    end

    # Make a GET request to the ResourceSpace API
    #
    # @param function [String] API function name
    # @param params [Hash] request parameters
    # @return [Hash] parsed JSON response
    def get(function, params = {})
      request(:get, function, params)
    end

    # Make a POST request to the ResourceSpace API
    #
    # @param function [String] API function name
    # @param params [Hash] request parameters
    # @return [Hash] parsed JSON response
    def post(function, params = {})
      request(:post, function, params)
    end

    # Upload a file to ResourceSpace
    #
    # @param file [File, String] file object or file path
    # @param params [Hash] additional parameters
    # @return [Hash] parsed JSON response
    def upload_file(file, params = {})
      file_param = if file.is_a?(String)
                     Faraday::UploadIO.new(file, mime_type_for_file(file))
                   else
                     Faraday::UploadIO.new(file, mime_type_for_file(file.path))
                   end

      params = params.merge(filedata: file_param)
      request(:post, 'upload_file', params, multipart: true)
    end

    # Download a file from ResourceSpace
    #
    # @param download_url [String] download URL
    # @param file_path [String] local file path to save to
    # @return [Boolean] true if successful
    def download_file(download_url, file_path)
      response = connection.get(download_url)

      if response.success?
        File.write(file_path, response.body)
        true
      else
        handle_error_response(response)
      end
    end

    # Test the API connection
    #
    # @return [Hash] system status information
    def test_connection
      get('get_system_status')
    end

    private

    # Make an HTTP request to the ResourceSpace API
    #
    # @param method [Symbol] HTTP method (:get or :post)
    # @param function [String] API function name
    # @param params [Hash] request parameters
    # @param multipart [Boolean] whether to use multipart encoding
    # @return [Hash] parsed JSON response
    def request(method, function, params = {}, multipart: false)
      # Prepare base parameters
      request_params = {
        user: config.user,
        function: function
      }.merge(params)

      # Build query string for signing
      query_string = URI.encode_www_form(request_params.reject { |_k, v| v.is_a?(Faraday::UploadIO) })

      # Generate signature
      signature = generate_signature(query_string)
      request_params[:sign] = signature
      request_params[:authmode] = config.auth_mode

      # Make the request
      response = if method == :get
                   connection.get('', request_params)
                 elsif multipart
                   connection.post('', request_params)
                 else
                   connection.post('', URI.encode_www_form(request_params))
                 end

      handle_response(response)
    end

    # Generate SHA256 signature for API authentication
    #
    # @param query_string [String] URL-encoded query string
    # @return [String] SHA256 hexadecimal signature
    def generate_signature(query_string)
      Digest::SHA256.hexdigest("#{config.private_key}#{query_string}")
    end

    # Get the Faraday connection instance
    #
    # @return [Faraday::Connection] configured connection
    def connection
      @connection ||= Faraday.new(url: config.url) do |conn|
        conn.request :multipart
        conn.request :url_encoded
        conn.adapter Faraday.default_adapter

        # Set timeout
        conn.options.timeout = config.timeout

        # Set headers
        conn.headers['User-Agent'] = config.user_agent
        config.default_headers.each { |key, value| conn.headers[key] = value }

        # Add response middleware
        conn.response :logger, config.logger if config.debug && config.logger
      end
    end

    # Handle API response and parse JSON
    #
    # @param response [Faraday::Response] HTTP response
    # @return [Hash] parsed JSON response
    # @raise [Error] if response indicates an error
    def handle_response(response)
      if response.success?
        parse_json_response(response.body)
      else
        handle_error_response(response)
      end
    end

    # Handle error responses and raise appropriate exceptions
    #
    # @param response [Faraday::Response] HTTP response
    # @raise [Error] appropriate error based on status code
    def handle_error_response(response)
      message = "HTTP #{response.status}"

      # Try to extract error message from response body
      if response.body && !response.body.empty?
        begin
          parsed_body = JSON.parse(response.body)
          message = parsed_body['error'] || parsed_body['message'] || message
        rescue JSON::ParserError
          message = response.body.length > 200 ? "#{response.body[0..200]}..." : response.body
        end
      end

      raise ResourceSpace.from_response(response.status, message, response.body)
    end

    # Parse JSON response body
    #
    # @param body [String] response body
    # @return [Hash] parsed JSON
    # @raise [ParseError] if JSON parsing fails
    def parse_json_response(body)
      return {} if body.nil? || body.empty?

      JSON.parse(body)
    rescue JSON::ParserError => e
      raise ParseError.new("Failed to parse JSON response: #{e.message}", data: { body: body })
    end

    # Get MIME type for a file
    #
    # @param file_path [String] file path
    # @return [String] MIME type
    def mime_type_for_file(file_path)
      require 'mime/types'
      MIME::Types.type_for(file_path).first&.content_type || 'application/octet-stream'
    end
  end
end
