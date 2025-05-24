# frozen_string_literal: true

module ResourceSpace
  # User management interface for ResourceSpace API
  #
  # @example
  #   users = client.users
  #
  #   # Get user list
  #   all_users = users.get_users
  #
  #   # Check permissions
  #   can_edit = users.check_permission("r")
  class User
    # @return [Client] the ResourceSpace client
    attr_reader :client

    # Initialize the user interface
    #
    # @param client [Client] ResourceSpace client instance
    def initialize(client)
      @client = client
    end

    # Get list of users
    #
    # @return [Array] array of user data
    def get_users
      client.get("get_users")
    end

    # Get users by permission
    #
    # @param permission [String] permission to check
    # @return [Array] users with the specified permission
    def get_users_by_permission(permission)
      client.get("get_users_by_permission", { param1: permission })
    end

    # Check if current user has a permission
    #
    # @param permission [String] permission to check
    # @return [Boolean] true if user has permission
    def check_permission(permission)
      response = client.get("checkperm", { param1: permission })
      response == true || response == "true" || response == 1 || response == "1"
    end

    # Login and get a session key
    #
    # @param username [String] username
    # @param password [String] password
    # @return [String] session key for subsequent requests
    def login(username, password)
      response = client.get("login", {
        param1: username,
        param2: password
      })

      # The response should be a session key
      response.is_a?(Hash) ? response["key"] || response["session_key"] : response
    end

    # Mark an email as invalid
    #
    # @param email [String] email address to mark as invalid
    # @return [Hash] response
    def mark_email_as_invalid(email)
      client.post("mark_email_as_invalid", { param1: email })
    end

    # Get user message
    #
    # @param message_id [Integer] message ID
    # @return [Hash] message details
    def get_user_message(message_id)
      client.get("get_user_message", { param1: message_id.to_s })
    end

    # Check if user can access a specific resource
    #
    # @param resource_id [Integer] resource ID
    # @return [Boolean] true if user can access the resource
    def can_access_resource?(resource_id)
      begin
        access_level = client.resources.get_resource_access(resource_id)
        access_level >= 0 # 0 = open access, -1 = no access
      rescue NotFoundError, AuthorizationError
        false
      end
    end

    # Check if user can edit a specific resource
    #
    # @param resource_id [Integer] resource ID
    # @return [Boolean] true if user can edit the resource
    def can_edit_resource?(resource_id)
      client.resources.edit_access?(resource_id)
    end

    # Get current user information
    #
    # @return [Hash] current user data
    def current_user
      # Note: ResourceSpace API doesn't have a direct "current user" endpoint
      # This would typically be implemented by getting user info based on the authenticated user
      # For now, we'll use the username from configuration and search for it
      users = get_users
      users.find { |user| user["username"] == client.config.user }
    end

    # Check multiple permissions at once
    #
    # @param permissions [Array<String>] array of permissions to check
    # @return [Hash] hash of permission => boolean pairs
    def check_permissions(permissions)
      result = {}
      Array(permissions).each do |permission|
        result[permission] = check_permission(permission)
      end
      result
    end

    # Get users with administrative privileges
    #
    # @return [Array] admin users
    def get_admin_users
      # Typically admin users have 'a' permission
      get_users_by_permission("a")
    end

    # Check if current user is an admin
    #
    # @return [Boolean] true if user is admin
    def admin?
      check_permission("a")
    end

    # Check if current user can manage users
    #
    # @return [Boolean] true if user can manage users
    def can_manage_users?
      check_permission("u")
    end

    # Check if current user can manage collections
    #
    # @return [Boolean] true if user can manage collections
    def can_manage_collections?
      check_permission("k")
    end

    # Check if current user can upload files
    #
    # @return [Boolean] true if user can upload files
    def can_upload?
      check_permission("c")
    end

    # Check if current user can download files
    #
    # @return [Boolean] true if user can download files
    def can_download?
      check_permission("d")
    end

    # Check if current user can edit resources
    #
    # @return [Boolean] true if user can edit resources
    def can_edit_resources?
      check_permission("e")
    end

    # Get user capabilities summary
    #
    # @return [Hash] summary of user capabilities
    def capabilities
      {
        admin: admin?,
        manage_users: can_manage_users?,
        manage_collections: can_manage_collections?,
        upload: can_upload?,
        download: can_download?,
        edit_resources: can_edit_resources?
      }
    end
  end
end
