# frozen_string_literal: true

module ResourceSpace
  # Resource management interface for ResourceSpace API
  #
  # @example
  #   resources = client.resources
  #
  #   # Create a new resource
  #   resource = resources.create_resource(name: "My Image")
  #
  #   # Upload a file
  #   uploaded = resources.upload_file(File.open("image.jpg"))
  #
  #   # Get resource data
  #   data = resources.get_resource_data(123)
  class Resource
    # @return [Client] the ResourceSpace client
    attr_reader :client

    # Initialize the resource interface
    #
    # @param client [Client] ResourceSpace client instance
    def initialize(client)
      @client = client
    end

    # Create a new resource
    #
    # @param name [String] resource name
    # @param resource_type [Integer] resource type ID (default: 1)
    # @param collection [Integer] collection ID to add resource to
    # @param metadata [Hash] metadata fields to set
    # @return [Hash] created resource data
    def create_resource(name: nil, resource_type: 1, collection: nil, metadata: {})
      params = {
        param1: resource_type.to_s
      }

      params[:param2] = collection.to_s if collection

      response = client.post("create_resource", params)
      resource_id = response.is_a?(Hash) ? response["ref"] || response["id"] : response

      # Set resource name if provided
      if name && resource_id
        update_field(resource_id, 8, name) # Field 8 is typically the title/name field
      end

      # Set additional metadata if provided
      metadata.each do |field, value|
        update_field(resource_id, field, value)
      end if metadata.any?

      get_resource_data(resource_id)
    end

    # Upload a file to ResourceSpace
    #
    # @param file [File, String] file object or file path
    # @param caption [String] file caption
    # @param no_exif [Boolean] whether to skip EXIF data extraction
    # @return [Hash] uploaded file data
    def upload_file(file, caption: nil, no_exif: false)
      params = {}
      params[:param1] = caption if caption
      params[:param2] = "1" if no_exif

      client.upload_file(file, params)
    end

    # Get resource data
    #
    # @param resource_id [Integer] resource ID
    # @return [Hash] resource data
    def get_resource_data(resource_id)
      client.get("get_resource_data", { param1: resource_id.to_s })
    end

    # Get resource field data
    #
    # @param resource_id [Integer] resource ID
    # @param field_id [Integer] field ID (optional)
    # @return [Hash] field data
    def get_resource_field_data(resource_id, field_id = nil)
      params = { param1: resource_id.to_s }
      params[:param2] = field_id.to_s if field_id

      client.get("get_resource_field_data", params)
    end

    # Update a resource field
    #
    # @param resource_id [Integer] resource ID
    # @param field_id [Integer] field ID
    # @param value [String] field value
    # @param node_values [Boolean] whether value contains node IDs
    # @return [Hash] response
    def update_field(resource_id, field_id, value, node_values: false)
      params = {
        param1: resource_id.to_s,
        param2: field_id.to_s,
        param3: value.to_s
      }
      params[:param4] = node_values.to_s if node_values

      client.post("update_field", params)
    end

    # Delete a resource
    #
    # @param resource_id [Integer] resource ID
    # @return [Hash] response
    def delete_resource(resource_id)
      client.post("delete_resource", { param1: resource_id.to_s })
    end

    # Copy a resource
    #
    # @param resource_id [Integer] source resource ID
    # @param resource_type [Integer] destination resource type (optional)
    # @return [Hash] new resource data
    def copy_resource(resource_id, resource_type: nil)
      params = { param1: resource_id.to_s }
      params[:param2] = resource_type.to_s if resource_type

      client.post("copy_resource", params)
    end

    # Get resource download path
    #
    # @param resource_id [Integer] resource ID
    # @param size [String] image size ('', 'pre', 'scr', 'thm', 'col')
    # @param page [Integer] page number for multi-page documents
    # @param ext [String] file extension override
    # @return [String] download path
    def get_resource_path(resource_id, size: "", page: 1, ext: "")
      params = {
        param1: resource_id.to_s,
        param2: size.to_s,
        param3: page.to_s
      }
      params[:param4] = ext if ext && !ext.empty?

      response = client.get("get_resource_path", params)
      response.is_a?(String) ? response : response["path"]
    end

    # Get alternative files for a resource
    #
    # @param resource_id [Integer] resource ID
    # @return [Array] alternative files data
    def get_alternative_files(resource_id)
      client.get("get_alternative_files", { param1: resource_id.to_s })
    end

    # Add an alternative file to a resource
    #
    # @param resource_id [Integer] resource ID
    # @param file [File, String] file object or file path
    # @param name [String] alternative file name
    # @param description [String] alternative file description
    # @return [Hash] response
    def add_alternative_file(resource_id, file, name: nil, description: nil)
      params = { param1: resource_id.to_s }
      params[:param2] = name if name
      params[:param3] = description if description

      client.upload_file(file, params.merge(function: "add_alternative_file"))
    end

    # Delete an alternative file
    #
    # @param resource_id [Integer] resource ID
    # @param alt_file_id [Integer] alternative file ID
    # @return [Hash] response
    def delete_alternative_file(resource_id, alt_file_id)
      client.post("delete_alternative_file", {
        param1: resource_id.to_s,
        param2: alt_file_id.to_s
      })
    end

    # Get resource types
    #
    # @return [Array] resource types
    def get_resource_types
      client.get("get_resource_types")
    end

    # Update resource type
    #
    # @param resource_id [Integer] resource ID
    # @param resource_type [Integer] new resource type ID
    # @return [Hash] response
    def update_resource_type(resource_id, resource_type)
      client.post("update_resource_type", {
        param1: resource_id.to_s,
        param2: resource_type.to_s
      })
    end

    # Get resource log
    #
    # @param resource_id [Integer] resource ID
    # @param entries [Integer] number of entries to return
    # @return [Array] log entries
    def get_resource_log(resource_id, entries: 50)
      client.get("get_resource_log", {
        param1: resource_id.to_s,
        param2: entries.to_s
      })
    end

    # Get all image sizes for a resource
    #
    # @param resource_id [Integer] resource ID
    # @return [Hash] image sizes data
    def get_resource_all_image_sizes(resource_id)
      client.get("get_resource_all_image_sizes", { param1: resource_id.to_s })
    end

    # Replace resource file
    #
    # @param resource_id [Integer] resource ID
    # @param file [File, String] new file
    # @param no_exif [Boolean] skip EXIF extraction
    # @return [Hash] response
    def replace_resource_file(resource_id, file, no_exif: false)
      params = { param1: resource_id.to_s }
      params[:param2] = "1" if no_exif

      client.upload_file(file, params.merge(function: "replace_resource_file"))
    end

    # Upload file by URL
    #
    # @param resource_id [Integer] resource ID
    # @param url [String] file URL
    # @param save_as [String] filename to save as
    # @param no_exif [Boolean] skip EXIF extraction
    # @return [Hash] response
    def upload_file_by_url(resource_id, url, save_as: nil, no_exif: false)
      params = {
        param1: resource_id.to_s,
        param2: url
      }
      params[:param3] = save_as if save_as
      params[:param4] = "1" if no_exif

      client.post("upload_file_by_url", params)
    end

    # Check if user has edit access to resource
    #
    # @param resource_id [Integer] resource ID
    # @return [Boolean] true if user has edit access
    def edit_access?(resource_id)
      response = client.get("get_edit_access", { param1: resource_id.to_s })
      response == true || response == "true" || response == 1 || response == "1"
    end

    # Get resource access level
    #
    # @param resource_id [Integer] resource ID
    # @return [Integer] access level
    def get_resource_access(resource_id)
      response = client.get("get_resource_access", { param1: resource_id.to_s })
      response.to_i
    end

    # Download a resource file
    #
    # @param resource_id [Integer] resource ID
    # @param file_path [String] local file path to save to
    # @param size [String] image size
    # @return [Boolean] true if successful
    def download_resource(resource_id, file_path, size: "")
      download_path = get_resource_path(resource_id, size: size)
      download_url = "#{client.config.url.gsub('/api/', '')}#{download_path}"

      client.download_file(download_url, file_path)
    end
  end
end
