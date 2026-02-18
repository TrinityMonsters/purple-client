# frozen_string_literal: true

require 'faraday'

module InheritanceSpec
  class BaseClient < Purple::Client
    domain 'https://example.com'
    authorization :custom_headers, 'Authorization' => 'Bearer token'

    path :status do
      root_method :status

      response :ok do
        body :default
      end
    end
  end

  class InheritedClient < BaseClient
  end

  class OverriddenClient < BaseClient
    domain 'https://other.example.com'
    authorization :custom_headers, 'Authorization' => 'Bearer different-token'
  end
end

RSpec.describe Purple::Client do
  let(:connection) { double('connection') }
  let(:headers) { {} }

  before do
    allow(connection).to receive(:headers=) { |value| headers.merge!(value) }
    allow(Faraday).to receive(:new).and_yield(connection).and_return(connection)
  end

  describe 'inheritance' do
    it 'inherits domain from parent class' do
      response = instance_double(Faraday::Response, status: 200, body: { ok: true }.to_json)
      expect(connection).to receive(:get).with('https://example.com/status', {}).and_return(response)

      InheritanceSpec::InheritedClient.status

      expect(InheritanceSpec::InheritedClient.domain).to eq('https://example.com')
    end

    it 'inherits authorization from parent class' do
      response = instance_double(Faraday::Response, status: 200, body: { ok: true }.to_json)
      allow(connection).to receive(:get).and_return(response)

      InheritanceSpec::InheritedClient.status

      expect(headers).to include('Authorization' => 'Bearer token')
      expect(InheritanceSpec::InheritedClient.authorization).to eq(InheritanceSpec::BaseClient.authorization)
    end

    it 'allows overriding inherited domain and authorization' do
      response = instance_double(Faraday::Response, status: 200, body: { ok: true }.to_json)
      expect(connection).to receive(:get).with('https://other.example.com/status', {}).and_return(response)

      InheritanceSpec::OverriddenClient.status

      expect(headers).to include('Authorization' => 'Bearer different-token')
      expect(InheritanceSpec::OverriddenClient.domain).to eq('https://other.example.com')
      expect(InheritanceSpec::OverriddenClient.authorization).not_to eq(InheritanceSpec::BaseClient.authorization)
    end
  end
end
