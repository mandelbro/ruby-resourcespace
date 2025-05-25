# ResourceSpace Ruby Client

A comprehensive Ruby client library for the [ResourceSpace](https://www.resourcespace.com/) open-source Digital Asset Management system. This gem provides an easy-to-use interface for managing web assets including images, CSS files, JavaScript files, fonts, and other digital resources.

[![Gem Version](https://badge.fury.io/rb/resourcespace-ruby.svg)](https://badge.fury.io/rb/resourcespace-ruby)
[![Documentation](https://img.shields.io/badge/docs-rubydoc.info-blue)](https://rubydoc.info/gems/resourcespace-ruby/0.1.2)

## Features

- **Complete API Coverage**: Supports all major ResourceSpace API endpoints
- **Web Asset Focused**: Optimized for managing web development assets (images, CSS, JS, fonts, icons)
- **Authentication**: Secure SHA256 signature-based authentication
- **File Operations**: Upload, download, and manage files with ease
- **Search & Collections**: Powerful search capabilities and collection management
- **Metadata Management**: Comprehensive metadata and field management
- **Error Handling**: Robust error handling with specific exception types
- **Configurable**: Flexible configuration options with global and instance-level settings

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'resourcespace-ruby'
```

And then execute:

```bash
$ bundle install
```

Or install it yourself as:

```bash
$ gem install resourcespace-ruby
```

## Quick Start

### Basic Configuration

```ruby
require 'resourcespace'

# Configure globally
ResourceSpace.configure do |config|
  config.url = "https://your-resourcespace.com/api/"
  config.user = "your_username"
  config.private_key = "your_private_key" # Get this from your ResourceSpace profile
  config.timeout = 30
end

# Or configure per instance
client = ResourceSpace::Client.new(
  url: "https://your-resourcespace.com/api/",
  user: "your_username",
  private_key: "your_private_key"
)
```

### Basic Usage

```ruby
# Test connection
status = client.test_connection
puts "Connected to ResourceSpace #{status['version']}"

# Search for web assets
results = client.search.search_web_assets("images")
puts "Found #{results.length} image assets"

# Upload a web asset
uploaded = client.resources.upload_file(
  File.open("assets/logo.png"),
  caption: "Company Logo"
)

# Create a collection for web assets
collection = client.collections.create_web_asset_collection(
  "Website Assets",
  asset_type: "images"
)

# Add resource to collection
client.collections.add_resource_to_collection(uploaded['ref'], collection['ref'])
```

## Web Asset Management

This gem is specifically designed to work well with web development assets:

### Upload Web Assets

```ruby
# Upload different types of web assets
logo = client.resources.upload_file("assets/logo.png")
stylesheet = client.resources.upload_file("assets/main.css")
script = client.resources.upload_file("assets/app.js")
font = client.resources.upload_file("assets/custom-font.woff2")
```

### Search for Specific Asset Types

```ruby
# Search by asset type
images = client.search.search_web_assets("images")
css_files = client.search.search_web_assets("css")
js_files = client.search.search_web_assets("javascript")
fonts = client.search.search_web_assets("fonts")

# Search by file extension
svg_files = client.search.search_by_extension(["svg"])
web_fonts = client.search.search_by_extension(["woff", "woff2", "ttf"])
```

### Organize with Collections

```ruby
# Create collections for different asset types
image_collection = client.collections.create_web_asset_collection(
  "Website Images",
  asset_type: "images"
)

css_collection = client.collections.create_web_asset_collection(
  "Stylesheets",
  asset_type: "css"
)

# Get all web asset collections
web_collections = client.collections.get_web_asset_collections
```

### Manage Web Asset Metadata

```ruby
# Set up web asset metadata fields (one-time setup)
client.metadata.create_web_asset_fields

# Update resource with web asset metadata
client.metadata.update_web_asset_metadata(resource_id, {
  title: "Hero Background Image",
  asset_type: "Image",
  dimensions: "1920x1080",
  usage_rights: "Creative Commons",
  purpose: "Website header background"
})
```

## Advanced Usage

### Resource Management

```ruby
# Create a new resource
resource = client.resources.create_resource(
  name: "Company Logo",
  resource_type: 1,
  metadata: {
    12 => "logo, branding, company", # Keywords field
    51 => "Image" # Custom asset type field
  }
)

# Get resource details
details = client.resources.get_resource_data(resource_id)

# Update resource metadata
client.resources.update_field(resource_id, 8, "New Title")

# Download resource
client.resources.download_resource(resource_id, "/local/path/file.jpg")

# Get alternative files
alternatives = client.resources.get_alternative_files(resource_id)
```

### Advanced Search

```ruby
# Advanced search with multiple criteria
results = client.search.advanced_search({
  title: "logo",
  extensions: ["png", "svg"],
  from_date: "2023-01-01",
  to_date: "2023-12-31"
}, {
  order_by: "date",
  sort: "desc",
  fetchrows: 20
})

# Search by date range
recent = client.search.search_by_date_range("2023-01-01", "2023-12-31")

# Get recently added resources
latest = client.search.recent_resources(10)
```

### Collection Management

```ruby
# Create collection
collection = client.collections.create_collection(
  "Marketing Assets",
  public: false,
  allow_changes: true
)

# Add multiple resources
resource_ids = [123, 124, 125]
client.collections.add_resources_to_collection(resource_ids, collection_id)

# Search public collections
public_collections = client.collections.search_public_collections("web")
```

### User & Permissions

```ruby
# Check user capabilities
capabilities = client.users.capabilities
puts "Can upload: #{capabilities[:upload]}"
puts "Can edit: #{capabilities[:edit_resources]}"

# Check specific permissions
can_download = client.users.can_download?
has_admin = client.users.admin?

# Check resource-specific permissions
can_edit_resource = client.users.can_edit_resource?(resource_id)
```

## Configuration Options

```ruby
ResourceSpace.configure do |config|
  config.url = "https://your-resourcespace.com/api/"  # Required
  config.user = "username"                           # Required
  config.private_key = "your_private_key"           # Required
  config.timeout = 30                               # Request timeout (seconds)
  config.retries = 3                                # Number of retry attempts
  config.verify_ssl = true                          # Verify SSL certificates
  config.auth_mode = "userkey"                      # Authentication mode
  config.debug = false                              # Enable debug logging
  config.logger = Logger.new(STDOUT)               # Custom logger
end
```

## Error Handling

The gem provides specific exception types for different error conditions:

```ruby
begin
  resource = client.resources.get_resource_data(999)
rescue ResourceSpace::NotFoundError => e
  puts "Resource not found: #{e.message}"
rescue ResourceSpace::AuthenticationError => e
  puts "Authentication failed: #{e.message}"
rescue ResourceSpace::AuthorizationError => e
  puts "Access denied: #{e.message}"
rescue ResourceSpace::ValidationError => e
  puts "Invalid data: #{e.message}"
rescue ResourceSpace::ServerError => e
  puts "Server error: #{e.message}"
rescue ResourceSpace::NetworkError => e
  puts "Network error: #{e.message}"
end
```

## Rails Integration

For Rails applications, add an initializer:

```ruby
# config/initializers/resourcespace.rb
ResourceSpace.configure do |config|
  config.url = ENV['RESOURCESPACE_URL']
  config.user = ENV['RESOURCESPACE_USER']
  config.private_key = ENV['RESOURCESPACE_PRIVATE_KEY']
  config.timeout = 30
end
```

Then use in your application:

```ruby
class AssetsController < ApplicationController
  def upload
    client = ResourceSpace::Client.new
    uploaded = client.resources.upload_file(params[:file])

    # Store reference in your model
    @asset = Asset.create(
      name: uploaded['title'],
      resourcespace_id: uploaded['ref'],
      file_type: uploaded['file_extension']
    )
  end
end
```

## Testing

Run the test suite:

```bash
$ bundle exec rspec
```

Run tests with coverage:

```bash
$ COVERAGE=1 bundle exec rspec
```

## Development

After checking out the repo, run:

```bash
$ bin/setup
$ bundle exec rake spec
```

To install this gem onto your local machine:

```bash
$ bundle exec rake install
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## API Reference

For complete API documentation, see the [ResourceSpace API documentation](https://www.resourcespace.com/knowledge-base/api/).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Support

- Documentation: [https://rubydoc.info/gems/resourcespace-ruby](https://rubydoc.info/gems/resourcespace-ruby)
- Issues: [https://github.com/mandelbro/resourcespace-ruby/issues](https://github.com/mandelbro/resourcespace-ruby/issues)
- ResourceSpace Documentation: [https://www.resourcespace.com/knowledge-base/](https://www.resourcespace.com/knowledge-base/)
