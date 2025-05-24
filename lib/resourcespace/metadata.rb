# frozen_string_literal: true

module ResourceSpace
  # Metadata management interface for ResourceSpace API
  #
  # @example
  #   metadata = client.metadata
  #
  #   # Get field options
  #   options = metadata.get_field_options(75)
  #
  #   # Create a resource type field
  #   field = metadata.create_resource_type_field(
  #     name: "Web Asset Type",
  #     type: "dropdown"
  #   )
  class Metadata
    # @return [Client] the ResourceSpace client
    attr_reader :client

    # Initialize the metadata interface
    #
    # @param client [Client] ResourceSpace client instance
    def initialize(client)
      @client = client
    end

    # Get field options for dropdown/checkbox fields
    #
    # @param field_id [Integer] field ID
    # @param node_info [Boolean] whether to include detailed node information
    # @return [Array] field options
    def get_field_options(field_id, node_info: false)
      params = { param1: field_id.to_s }
      params[:param2] = node_info ? "true" : "false"

      client.get("get_field_options", params)
    end

    # Get node ID for a field value
    #
    # @param field_id [Integer] field ID
    # @param value [String] field value
    # @return [Integer] node ID
    def get_node_id(field_id, value)
      response = client.get("get_node_id", {
        param1: field_id.to_s,
        param2: value
      })
      response.to_i
    end

    # Get all nodes for a field
    #
    # @param field_id [Integer] field ID
    # @return [Array] field nodes
    def get_nodes(field_id)
      client.get("get_nodes", { param1: field_id.to_s })
    end

    # Set/create a node value
    #
    # @param field_id [Integer] field ID
    # @param value [String] node value
    # @param return_existing [Boolean] return existing node if it exists
    # @return [Integer] node ID
    def set_node(field_id, value, return_existing: true)
      params = {
        param1: field_id.to_s,
        param2: value
      }
      params[:param3] = return_existing ? "true" : "false"

      response = client.post("set_node", params)
      response.to_i
    end

    # Add resource nodes (multiple field values)
    #
    # @param resource_id [Integer] resource ID
    # @param field_id [Integer] field ID
    # @param node_ids [Array<Integer>] array of node IDs
    # @return [Hash] response
    def add_resource_nodes(resource_id, field_id, node_ids)
      node_ids_str = Array(node_ids).join(",")

      client.post("add_resource_nodes", {
        param1: resource_id.to_s,
        param2: field_id.to_s,
        param3: node_ids_str
      })
    end

    # Add resource nodes for multiple fields
    #
    # @param resource_id [Integer] resource ID
    # @param field_data [Hash] hash of field_id => node_ids pairs
    # @return [Hash] response
    def add_resource_nodes_multi(resource_id, field_data)
      # Convert field_data to the format expected by the API
      # This might need adjustment based on the exact API format
      params = { param1: resource_id.to_s }

      field_data.each_with_index do |(field_id, node_ids), index|
        node_ids_str = Array(node_ids).join(",")
        params["param#{index + 2}"] = "#{field_id}:#{node_ids_str}"
      end

      client.post("add_resource_nodes_multi", params)
    end

    # Update a field definition
    #
    # @param field_id [Integer] field ID
    # @param properties [Hash] field properties to update
    # @return [Hash] response
    def update_field(field_id, properties = {})
      params = { param1: field_id.to_s }

      # Add properties as additional parameters
      properties.each_with_index do |(key, value), index|
        params["param#{index + 2}"] = "#{key}:#{value}"
      end

      client.post("update_field", params)
    end

    # Get resource type fields
    #
    # @param resource_type [Integer] resource type ID
    # @return [Array] fields for the resource type
    def get_resource_type_fields(resource_type = nil)
      params = {}
      params[:param1] = resource_type.to_s if resource_type

      client.get("get_resource_type_fields", params)
    end

    # Create a new resource type field
    #
    # @param name [String] field name
    # @param type [String] field type ("text", "dropdown", "checkbox", "date", etc.)
    # @param resource_types [Array<Integer>] resource types this field applies to
    # @param options [Hash] additional field options
    # @return [Hash] created field data
    def create_resource_type_field(name:, type:, resource_types: [1], **options)
      params = {
        param1: name,
        param2: type,
        param3: Array(resource_types).join(",")
      }

      # Add additional options
      options.each_with_index do |(key, value), index|
        params["param#{index + 4}"] = "#{key}:#{value}"
      end

      client.post("create_resource_type_field", params)
    end

    # Toggle active state for nodes
    #
    # @param field_id [Integer] field ID
    # @param node_ids [Array<Integer>] node IDs to toggle
    # @param active [Boolean] whether to activate or deactivate
    # @return [Hash] response
    def toggle_active_state_for_nodes(field_id, node_ids, active: true)
      node_ids_str = Array(node_ids).join(",")

      client.post("toggle_active_state_for_nodes", {
        param1: field_id.to_s,
        param2: node_ids_str,
        param3: active ? "1" : "0"
      })
    end

    # Get metadata schema for web assets
    #
    # @return [Hash] recommended metadata fields for web assets
    def web_asset_schema
      {
        8 => "Title/Name",
        12 => "Keywords/Tags",
        51 => "Asset Type", # Custom field for web asset type
        52 => "Usage Rights", # Custom field for usage/license
        53 => "Dimensions", # Custom field for dimensions
        54 => "File Size", # Custom field for file size
        55 => "Compression", # Custom field for compression type
        56 => "Color Profile", # Custom field for color profile
        57 => "Purpose/Context" # Custom field for intended use
      }
    end

    # Create web asset metadata fields
    #
    # @param resource_types [Array<Integer>] resource types to apply fields to
    # @return [Array] created field data
    def create_web_asset_fields(resource_types: [1])
      fields_to_create = [
        {
          name: "Web Asset Type",
          type: "dropdown",
          options: ["Image", "CSS", "JavaScript", "Font", "Icon", "Video", "Audio"]
        },
        {
          name: "Usage Rights",
          type: "dropdown",
          options: ["Public Domain", "Creative Commons", "Licensed", "Proprietary"]
        },
        {
          name: "Dimensions",
          type: "text",
          description: "Width x Height (e.g., 1920x1080)"
        },
        {
          name: "File Size",
          type: "text",
          description: "File size in bytes/KB/MB"
        },
        {
          name: "Compression",
          type: "dropdown",
          options: ["None", "Lossless", "Lossy", "Optimized"]
        },
        {
          name: "Color Profile",
          type: "dropdown",
          options: ["sRGB", "Adobe RGB", "ProPhoto RGB", "CMYK", "Grayscale"]
        },
        {
          name: "Purpose/Context",
          type: "text",
          description: "Intended use or context for this asset"
        }
      ]

      created_fields = []
      fields_to_create.each do |field_data|
        options = field_data.dup
        name = options.delete(:name)
        type = options.delete(:type)

        created_field = create_resource_type_field(
          name: name,
          type: type,
          resource_types: resource_types,
          **options
        )
        created_fields << created_field
      end

      created_fields
    end

    # Update resource with web asset metadata
    #
    # @param resource_id [Integer] resource ID
    # @param metadata [Hash] web asset metadata
    # @return [Array] array of update responses
    def update_web_asset_metadata(resource_id, metadata = {})
      updates = []

      schema = web_asset_schema

      metadata.each do |field_name, value|
        field_id = case field_name.to_s.downcase
                   when "title", "name"
                     8
                   when "keywords", "tags"
                     12
                   when "asset_type", "type"
                     51
                   when "usage_rights", "rights", "license"
                     52
                   when "dimensions", "size"
                     53
                   when "file_size"
                     54
                   when "compression"
                     55
                   when "color_profile", "color"
                     56
                   when "purpose", "context", "description"
                     57
                   else
                     field_name.to_i if field_name.to_s.match?(/^\d+$/)
                   end

        if field_id
          update_response = client.resources.update_field(resource_id, field_id, value.to_s)
          updates << { field_id: field_id, field_name: field_name, response: update_response }
        end
      end

      updates
    end
  end
end
