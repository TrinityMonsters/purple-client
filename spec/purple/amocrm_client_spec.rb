# frozen_string_literal: true

require 'faraday'

module Amocrm
  class Client < Purple::Client
    domain 'https://www.amocrm.ru'

    path :oauth2 do
      path :access_token, method: :post do
        root_method :access_token

        params do |client_id:, client_secret:, redirect_uri:, code:, grant_type: :authorization_code|
          { client_id:, client_secret:, redirect_uri:, code:, grant_type: }
        end

        response :ok do
          body :default
        end
      end
    end
  end
end

RSpec.describe Amocrm::Client do
  let(:connection) { double('connection') }

  before do
    allow(connection).to receive(:headers=)
    allow(Faraday).to receive(:new).with(url: 'https://www.amocrm.ru').and_yield(connection).and_return(connection)
  end

  describe '.access_token' do
    it 'posts to oauth2/access_token with params and returns body' do
      response = instance_double(Faraday::Response, status: 200, body: { token: 'abc' }.to_json)

      expect(connection).to receive(:post).with(
        'https://www.amocrm.ru/oauth2/access_token',
        {
          client_id: 'id',
          client_secret: 'secret',
          redirect_uri: 'redirect',
          code: 'code',
          grant_type: 'authorization_code'
        }.to_json
      ).and_return(response)

      result = described_class.access_token(
        client_id: 'id',
        client_secret: 'secret',
        redirect_uri: 'redirect',
        code: 'code'
      )

      expect(result).to eq(response.body)
    end
  end
end

