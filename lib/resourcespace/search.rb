# frozen_string_literal: true

module ResourceSpace
  # Search interface for ResourceSpace API
  #
  # @example
  #   search = client.search
  #
  #   # Basic search
  #   results = search.do_search("cat")
  #
  #   # Advanced search with parameters
  #   results = search.do_search("web assets", {
  #     order_by: "date",
  #     sort: "desc",
  #     fetchrows: 20
  #   })
  #
  #   # Search with previews
  #   results = search.search_get_previews("images", {
  #     getsizes: "col,thm,scr",
  #     fetchrows: 10
  #   })
  class Search
    # @return [Client] the ResourceSpace client
    attr_reader :client

    # Initialize the search interface
    #
    # @param client [Client] ResourceSpace client instance
    def initialize(client)
      @client = client
    end

    # Perform a basic search
    #
    # @param search_term [String] search term
    # @param options [Hash] search options
    # @option options [String] :restypes resource types to search (e.g., "1,2,3")
    # @option options [String] :order_by field to order by ("relevance", "popularity", "date", "colour", "country", "title", "file_path", "resourceid", "extension", "user", "created")
    # @option options [String] :sort sort direction ("asc" or "desc")
    # @option options [Integer] :offset starting offset for results
    # @option options [Integer] :fetchrows number of results to fetch
    # @option options [String] :archive archive status ("0" = live resources, "1" = archived, "2" = both)
    # @option options [Integer] :daylimit only return resources modified in the last X days
    # @return [Hash] search results
    def do_search(search_term, options = {})
      params = build_search_params(search_term, options)
      client.get("do_search", params)
    end

    # Search and get previews in one call
    #
    # @param search_term [String] search term
    # @param options [Hash] search options
    # @option options [String] :getsizes image sizes to include ("col,thm,scr,pre")
    # @option options [String] :order_by field to order by
    # @option options [String] :sort sort direction ("asc" or "desc")
    # @option options [Integer] :fetchrows number of results to fetch
    # @option options [String] :archive archive status
    # @return [Hash] search results with preview data
    def search_get_previews(search_term, options = {})
      params = build_search_params(search_term, options)
      params[:param6] = options[:getsizes] if options[:getsizes]

      client.get("search_get_previews", params)
    end

    # Search for web assets (images, CSS, JS, fonts)
    #
    # @param asset_type [String] type of web asset ("image", "css", "javascript", "font", "icon")
    # @param options [Hash] search options
    # @return [Hash] search results filtered for web assets
    def search_web_assets(asset_type = nil, options = {})
      search_terms = []

      case asset_type&.downcase
      when "image", "images"
        search_terms << "extension:jpg OR extension:jpeg OR extension:png OR extension:gif OR extension:svg OR extension:webp"
      when "css", "stylesheet", "stylesheets"
        search_terms << "extension:css"
      when "javascript", "js"
        search_terms << "extension:js"
      when "font", "fonts"
        search_terms << "extension:woff OR extension:woff2 OR extension:ttf OR extension:otf OR extension:eot"
      when "icon", "icons"
        search_terms << "extension:ico OR extension:svg"
      else
        # Search for all common web asset types
        search_terms << "extension:jpg OR extension:jpeg OR extension:png OR extension:gif OR extension:svg OR extension:webp OR extension:css OR extension:js OR extension:woff OR extension:woff2 OR extension:ico"
      end

      search_term = search_terms.join(" OR ")
      search_term += " #{options.delete(:query)}" if options[:query]

      do_search(search_term, options)
    end

    # Search resources by file extension
    #
    # @param extensions [String, Array] file extension(s) to search for
    # @param options [Hash] search options
    # @return [Hash] search results
    def search_by_extension(extensions, options = {})
      extensions = Array(extensions).map(&:to_s)
      search_term = extensions.map { |ext| "extension:#{ext.gsub(/^\./, '')}" }.join(" OR ")

      do_search(search_term, options)
    end

    # Search resources by date range
    #
    # @param from_date [Date, String] start date (YYYY-MM-DD format)
    # @param to_date [Date, String] end date (YYYY-MM-DD format)
    # @param options [Hash] search options
    # @return [Hash] search results
    def search_by_date_range(from_date, to_date = nil, options = {})
      from_str = format_date(from_date)
      to_str = to_date ? format_date(to_date) : from_str

      search_term = "created:#{from_str}"
      search_term += ";#{to_str}" if to_date

      do_search(search_term, options)
    end

    # Search resources by collection
    #
    # @param collection_id [Integer] collection ID
    # @param options [Hash] search options
    # @return [Hash] search results
    def search_by_collection(collection_id, options = {})
      search_term = "!collection#{collection_id}"
      do_search(search_term, options)
    end

    # Search resources by resource IDs
    #
    # @param resource_ids [Array<Integer>] array of resource IDs
    # @param options [Hash] search options
    # @return [Hash] search results
    def search_by_ids(resource_ids, options = {})
      ids = Array(resource_ids).join(":")
      search_term = "!list#{ids}"
      do_search(search_term, options)
    end

    # Get recently added resources
    #
    # @param count [Integer] number of recent resources to return
    # @param options [Hash] search options
    # @return [Hash] search results
    def recent_resources(count = 10, options = {})
      search_term = "!last#{count}"
      do_search(search_term, options)
    end

    # Search resources by tag
    #
    # @param tag [String] tag name
    # @param options [Hash] search options
    # @return [Hash] search results
    def search_by_tag(tag, options = {})
      search_term = "tag:#{tag}"
      do_search(search_term, options)
    end

    # Search resources by user
    #
    # @param username [String] username
    # @param options [Hash] search options
    # @return [Hash] search results
    def search_by_user(username, options = {})
      search_term = "user:#{username}"
      do_search(search_term, options)
    end

    # Search resources by title/name
    #
    # @param title [String] resource title
    # @param options [Hash] search options
    # @return [Hash] search results
    def search_by_title(title, options = {})
      search_term = "title:#{title}"
      do_search(search_term, options)
    end

    # Advanced search with multiple criteria
    #
    # @param criteria [Hash] search criteria
    # @option criteria [String] :title title search
    # @option criteria [String] :tag tag search
    # @option criteria [String] :user user search
    # @option criteria [Array<String>] :extensions file extensions
    # @option criteria [String] :from_date start date
    # @option criteria [String] :to_date end date
    # @param options [Hash] search options
    # @return [Hash] search results
    def advanced_search(criteria = {}, options = {})
      search_parts = []

      search_parts << "title:#{criteria[:title]}" if criteria[:title]
      search_parts << "tag:#{criteria[:tag]}" if criteria[:tag]
      search_parts << "user:#{criteria[:user]}" if criteria[:user]

      if criteria[:extensions]
        ext_search = Array(criteria[:extensions]).map { |ext| "extension:#{ext.gsub(/^\./, '')}" }.join(" OR ")
        search_parts << "(#{ext_search})"
      end

      if criteria[:from_date]
        date_search = "created:#{format_date(criteria[:from_date])}"
        date_search += ";#{format_date(criteria[:to_date])}" if criteria[:to_date]
        search_parts << date_search
      end

      search_term = search_parts.join(" AND ")
      search_term = criteria[:query] if search_term.empty? && criteria[:query]

      do_search(search_term, options)
    end

    private

    # Build search parameters hash
    #
    # @param search_term [String] search term
    # @param options [Hash] search options
    # @return [Hash] parameters hash
    def build_search_params(search_term, options = {})
      params = { param1: search_term }

      params[:param2] = options[:restypes] if options[:restypes]
      params[:param3] = options[:order_by] if options[:order_by]
      params[:param4] = options[:offset] if options[:offset]
      params[:param5] = options[:fetchrows] if options[:fetchrows]
      params[:param6] = options[:sort] if options[:sort]
      params[:param7] = options[:archive] if options[:archive]
      params[:param8] = options[:daylimit] if options[:daylimit]

      params
    end

    # Format date for ResourceSpace API
    #
    # @param date [Date, String] date to format
    # @return [String] formatted date string
    def format_date(date)
      case date
      when Date
        date.strftime("%Y-%m-%d")
      when Time
        date.strftime("%Y-%m-%d")
      else
        date.to_s
      end
    end
  end
end
