# frozen_string_literal: true

module ResourceSpace
  # Base error class for all ResourceSpace errors
  class Error < StandardError
    # @return [Hash, nil] additional error data
    attr_reader :data

    # @return [Integer, nil] HTTP status code if applicable
    attr_reader :status_code

    # @return [String, nil] response body if applicable
    attr_reader :response_body

    # Initialize a new error
    #
    # @param message [String] error message
    # @param data [Hash] additional error data
    # @param status_code [Integer] HTTP status code
    # @param response_body [String] HTTP response body
    def initialize(message = nil, data: nil, status_code: nil, response_body: nil)
      @data = data
      @status_code = status_code
      @response_body = response_body
      super(message)
    end

    # Convert error to a hash representation
    #
    # @return [Hash] error as a hash
    def to_h
      {
        error: self.class.name,
        message: message,
        status_code: status_code,
        data: data
      }.compact
    end
  end

  # Configuration validation error
  class ConfigurationError < Error; end

  # Authentication error
  class AuthenticationError < Error; end

  # Authorization error (user doesn't have permission)
  class AuthorizationError < Error; end

  # Resource not found error
  class NotFoundError < Error; end

  # Validation error (invalid parameters)
  class ValidationError < Error; end

  # Rate limiting error
  class RateLimitError < Error; end

  # Server error (5xx responses)
  class ServerError < Error; end

  # Network/connection error
  class NetworkError < Error; end

  # Request timeout error
  class TimeoutError < Error; end

  # File upload error
  class UploadError < Error; end

  # API response parsing error
  class ParseError < Error; end

  # Resource already exists error
  class ConflictError < Error; end

  # API quota exceeded error
  class QuotaExceededError < Error; end

  # Generic client error (4xx responses)
  class ClientError < Error; end

  # Method to create appropriate error based on HTTP status code
  #
  # @param status_code [Integer] HTTP status code
  # @param message [String] error message
  # @param response_body [String] HTTP response body
  # @return [Error] appropriate error instance
  def self.from_response(status_code, message = nil, response_body = nil)
    case status_code
    when 400
      ValidationError.new(message, status_code: status_code, response_body: response_body)
    when 401
      AuthenticationError.new(message, status_code: status_code, response_body: response_body)
    when 403
      AuthorizationError.new(message, status_code: status_code, response_body: response_body)
    when 404
      NotFoundError.new(message, status_code: status_code, response_body: response_body)
    when 409
      ConflictError.new(message, status_code: status_code, response_body: response_body)
    when 429
      RateLimitError.new(message, status_code: status_code, response_body: response_body)
    when 400..499
      ClientError.new(message, status_code: status_code, response_body: response_body)
    when 500..599
      ServerError.new(message, status_code: status_code, response_body: response_body)
    else
      Error.new(message, status_code: status_code, response_body: response_body)
    end
  end
end
