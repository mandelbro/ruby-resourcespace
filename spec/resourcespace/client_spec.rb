# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ResourceSpace::Client do
  let(:valid_config) { super() }
  let(:client) { create_test_client }

  describe '#initialize' do
    it 'creates a client with valid configuration' do
      expect(client).to be_a(ResourceSpace::Client)
      expect(client.config).to be_a(ResourceSpace::Configuration)
      expect(client.config.url).to eq('https://demo.resourcespace.com/api/')
      expect(client.config.user).to eq('test_user')
    end

    it 'initializes API interfaces' do
      expect(client.resources).to be_a(ResourceSpace::Resource)
      expect(client.collections).to be_a(ResourceSpace::Collection)
      expect(client.search).to be_a(ResourceSpace::Search)
      expect(client.users).to be_a(ResourceSpace::User)
      expect(client.metadata).to be_a(ResourceSpace::Metadata)
    end

    it 'raises ConfigurationError with invalid configuration' do
      expect do
        ResourceSpace::Client.new(url: '', user: '', private_key: '')
      end.to raise_error(ResourceSpace::ConfigurationError)
    end

    it 'accepts additional configuration options' do
      client = ResourceSpace::Client.new(**valid_config, timeout: 60, debug: true)
      expect(client.config.timeout).to eq(60)
      expect(client.config.debug).to be(true)
    end
  end

  describe '#get' do
    it 'makes a GET request to the API' do
      response_data = { 'status' => 'active', 'version' => '9.0' }
      stub_api_request(:get, 'get_system_status', {}, response_data)

      result = client.get('get_system_status')
      expect(result).to eq(response_data)
    end

    it 'includes parameters in the request' do
      response_data = [{ 'ref' => 123, 'title' => 'Test Resource' }]
      stub_api_request(:get, 'do_search', { param1: 'test' }, response_data)

      result = client.get('do_search', { param1: 'test' })
      expect(result).to eq(response_data)
    end

    it 'raises appropriate error for 404 response' do
      stub_error_response(:get, 'get_resource_data', 404, 'Resource not found', { param1: '999' })

      expect do
        client.get('get_resource_data', { param1: '999' })
      end.to raise_error(ResourceSpace::NotFoundError)
    end

    it 'raises appropriate error for 401 response' do
      stub_error_response(:get, 'get_system_status', 401, 'Authentication failed')

      expect do
        client.get('get_system_status')
      end.to raise_error(ResourceSpace::AuthenticationError)
    end
  end

  describe '#post' do
    it 'makes a POST request to the API' do
      response_data = { 'ref' => 123 }
      stub_api_request(:post, 'create_resource', { param1: '1' }, response_data)

      result = client.post('create_resource', { param1: '1' })
      expect(result).to eq(response_data)
    end

    it 'handles validation errors' do
      stub_error_response(:post, 'create_resource', 400, 'Invalid resource type', { param1: 'invalid' })

      expect do
        client.post('create_resource', { param1: 'invalid' })
      end.to raise_error(ResourceSpace::ValidationError)
    end
  end

  describe '#test_connection' do
    it 'tests the API connection successfully' do
      response_data = { 'status' => 'active', 'version' => '9.0' }
      stub_api_request(:get, 'get_system_status', {}, response_data)

      result = client.test_connection
      expect(result).to eq(response_data)
      expect(result['status']).to eq('active')
    end

    it 'raises error when connection fails' do
      stub_error_response(:get, 'get_system_status', 500, 'Server error')

      expect do
        client.test_connection
      end.to raise_error(ResourceSpace::ServerError)
    end
  end

  describe 'signature generation' do
    it 'generates correct SHA256 signature' do
      # This tests the private method indirectly through a request
      response_data = { 'status' => 'ok' }

      # The stub will verify the signature is correct
      stub_api_request(:get, 'get_system_status', {}, response_data)

      expect { client.get('get_system_status') }.not_to raise_error
    end
  end

  describe 'error handling' do
    it 'handles JSON parsing errors' do
      # Need to match the exact request parameters that will be sent
      request_params = {
        user: 'test_user',
        function: 'get_system_status'
      }
      query_string = URI.encode_www_form(request_params)
      signature = Digest::SHA256.hexdigest("test_private_key_12345#{query_string}")
      request_params[:sign] = signature
      request_params[:authmode] = 'userkey'

      stub_request(:get, 'https://demo.resourcespace.com/api/')
        .with(query: request_params)
        .to_return(status: 200, body: 'invalid json', headers: { 'Content-Type' => 'application/json' })

      expect do
        client.get('get_system_status')
      end.to raise_error(ResourceSpace::ParseError)
    end

    it 'handles empty response body' do
      # Need to match the exact request parameters that will be sent
      request_params = {
        user: 'test_user',
        function: 'get_system_status'
      }
      query_string = URI.encode_www_form(request_params)
      signature = Digest::SHA256.hexdigest("test_private_key_12345#{query_string}")
      request_params[:sign] = signature
      request_params[:authmode] = 'userkey'

      stub_request(:get, 'https://demo.resourcespace.com/api/')
        .with(query: request_params)
        .to_return(status: 200, body: '', headers: { 'Content-Type' => 'application/json' })

      result = client.get('get_system_status')
      expect(result).to eq({})
    end
  end

  describe 'web asset specific functionality' do
    context 'when working with web assets' do
      it 'can upload image files' do
        # This would be tested in the Resource class specs
        expect(client.resources).to respond_to(:upload_file)
      end

      it 'can search for web assets' do
        # This would be tested in the Search class specs
        expect(client.search).to respond_to(:search_web_assets)
      end

      it 'can create collections for web assets' do
        # This would be tested in the Collection class specs
        expect(client.collections).to respond_to(:create_web_asset_collection)
      end

      it 'can manage web asset metadata' do
        # This would be tested in the Metadata class specs
        expect(client.metadata).to respond_to(:update_web_asset_metadata)
      end
    end
  end

  describe 'configuration management' do
    before do
      # Always start with a clean configuration state
      ResourceSpace.reset_config!
    end

    after do
      # Reset configuration after each test
      ResourceSpace.reset_config!
    end

    it 'uses global configuration when available' do
      ResourceSpace.configure do |config|
        config.url = 'https://global.resourcespace.com/api/'
        config.user = 'global_user'
        config.private_key = 'global_key'
      end

      client = ResourceSpace::Client.new
      expect(client.config.url).to eq('https://global.resourcespace.com/api/')
      expect(client.config.user).to eq('global_user')
    end

    it 'overrides global configuration with instance configuration' do
      ResourceSpace.configure do |config|
        config.url = 'https://global.resourcespace.com/api/'
        config.user = 'global_user'
        config.private_key = 'global_key'
      end

      client = ResourceSpace::Client.new(user: 'instance_user')
      expect(client.config.url).to eq('https://global.resourcespace.com/api/')
      expect(client.config.user).to eq('instance_user')
    end
  end
end
