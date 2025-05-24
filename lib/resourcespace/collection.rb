# frozen_string_literal: true

module ResourceSpace
  # Collection management interface for ResourceSpace API
  #
  # @example
  #   collections = client.collections
  #
  #   # Get user collections
  #   user_collections = collections.get_user_collections
  #
  #   # Create a new collection
  #   collection = collections.create_collection("My Web Assets")
  #
  #   # Add resources to collection
  #   collections.add_resource_to_collection(123, collection_id)
  class Collection
    # @return [Client] the ResourceSpace client
    attr_reader :client

    # Initialize the collection interface
    #
    # @param client [Client] ResourceSpace client instance
    def initialize(client)
      @client = client
    end

    # Get user collections
    #
    # @param user [String] username (optional, defaults to current user)
    # @return [Array] user collections
    def get_user_collections(user = nil)
      params = {}
      params[:param1] = user if user

      client.get("get_user_collections", params)
    end

    # Create a new collection
    #
    # @param name [String] collection name
    # @param public [Boolean] whether collection is public
    # @param allow_changes [Boolean] whether to allow changes to collection
    # @return [Hash] created collection data
    def create_collection(name, public: false, allow_changes: true)
      params = {
        param1: name,
        param2: public ? "1" : "0"
      }
      params[:param3] = allow_changes ? "1" : "0"

      client.post("create_collection", params)
    end

    # Delete a collection
    #
    # @param collection_id [Integer] collection ID
    # @return [Hash] response
    def delete_collection(collection_id)
      client.post("delete_collection", { param1: collection_id.to_s })
    end

    # Get collection details
    #
    # @param collection_id [Integer] collection ID
    # @return [Hash] collection details
    def get_collection(collection_id)
      client.get("get_collection", { param1: collection_id.to_s })
    end

    # Save collection (update collection details)
    #
    # @param collection_id [Integer] collection ID
    # @param name [String] new collection name
    # @param public [Boolean] whether collection is public
    # @param allow_changes [Boolean] whether to allow changes
    # @return [Hash] response
    def save_collection(collection_id, name: nil, public: nil, allow_changes: nil)
      params = { param1: collection_id.to_s }
      params[:param2] = name if name
      params[:param3] = public ? "1" : "0" unless public.nil?
      params[:param4] = allow_changes ? "1" : "0" unless allow_changes.nil?

      client.post("save_collection", params)
    end

    # Add a resource to a collection
    #
    # @param resource_id [Integer] resource ID
    # @param collection_id [Integer] collection ID
    # @return [Hash] response
    def add_resource_to_collection(resource_id, collection_id)
      client.post("add_resource_to_collection", {
        param1: resource_id.to_s,
        param2: collection_id.to_s
      })
    end

    # Remove a resource from a collection
    #
    # @param resource_id [Integer] resource ID
    # @param collection_id [Integer] collection ID
    # @return [Hash] response
    def remove_resource_from_collection(resource_id, collection_id)
      client.post("remove_resource_from_collection", {
        param1: resource_id.to_s,
        param2: collection_id.to_s
      })
    end

    # Show or hide a collection
    #
    # @param collection_id [Integer] collection ID
    # @param show [Boolean] true to show, false to hide
    # @return [Hash] response
    def show_hide_collection(collection_id, show: true)
      client.post("show_hide_collection", {
        param1: collection_id.to_s,
        param2: show ? "1" : "0"
      })
    end

    # Send collection to admin
    #
    # @param collection_id [Integer] collection ID
    # @param message [String] message to admin
    # @return [Hash] response
    def send_collection_to_admin(collection_id, message = "")
      client.post("send_collection_to_admin", {
        param1: collection_id.to_s,
        param2: message
      })
    end

    # Search public collections
    #
    # @param search_term [String] search term
    # @return [Array] matching public collections
    def search_public_collections(search_term)
      client.get("search_public_collections", { param1: search_term })
    end

    # Get featured collections
    #
    # @return [Array] featured collections
    def get_featured_collections
      client.get("get_featured_collections")
    end

    # Delete all resources in a collection
    #
    # @param collection_id [Integer] collection ID
    # @return [Hash] response
    def delete_resources_in_collection(collection_id)
      client.post("delete_resources_in_collection", { param1: collection_id.to_s })
    end

    # Add multiple resources to a collection
    #
    # @param resource_ids [Array<Integer>] array of resource IDs
    # @param collection_id [Integer] collection ID
    # @return [Array] array of responses
    def add_resources_to_collection(resource_ids, collection_id)
      Array(resource_ids).map do |resource_id|
        add_resource_to_collection(resource_id, collection_id)
      end
    end

    # Remove multiple resources from a collection
    #
    # @param resource_ids [Array<Integer>] array of resource IDs
    # @param collection_id [Integer] collection ID
    # @return [Array] array of responses
    def remove_resources_from_collection(resource_ids, collection_id)
      Array(resource_ids).map do |resource_id|
        remove_resource_from_collection(resource_id, collection_id)
      end
    end

    # Create a collection for web assets
    #
    # @param name [String] collection name
    # @param asset_type [String] type of web assets ("images", "css", "js", "fonts", "icons")
    # @param public [Boolean] whether collection is public
    # @return [Hash] created collection data
    def create_web_asset_collection(name, asset_type: nil, public: false)
      collection_name = asset_type ? "#{name} - #{asset_type.capitalize}" : name
      create_collection(collection_name, public: public)
    end

    # Get collections containing web assets
    #
    # @param asset_type [String] type of web assets to filter by
    # @return [Array] collections with web assets
    def get_web_asset_collections(asset_type: nil)
      collections = get_user_collections

      # Filter collections that likely contain web assets based on name
      web_asset_keywords = %w[web asset css js javascript image icon font stylesheet]

      if asset_type
        web_asset_keywords << asset_type.downcase
      end

      collections.select do |collection|
        name = collection["name"]&.downcase || ""
        web_asset_keywords.any? { |keyword| name.include?(keyword) }
      end
    end
  end
end
