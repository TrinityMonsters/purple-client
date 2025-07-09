# frozen_string_literal: true

require 'faraday'

RSpec.describe Purple::Client do
  it "has a version number" do
    expect(Purple::Client::VERSION).not_to be nil
  end
end

module UnipileConfig
  def self.api_key
    'secret'
  end
end

module Events
  def self.unipile(url:, params:, headers:, response:, resource:); end
end

class Unipile
  module Linkedin
  end
end

class Unipile::Linkedin::PurpleClient < Purple::Client
  domain 'https://api4.unipile.com:13451/api/v1'
  authorization :custom_headers, 'X-API-KEY' => UnipileConfig.api_key

  additional_callback_arguments :resource

  callback do |url, params, headers, response, resource|
    Events.unipile(url:, params:, headers:, response:, resource:)
  end

  path :users do
    path :invite, method: :post do
      root_method :linkedin_invite

      params do |provider_id:, account_id:, message:|
        {
          provider_id: provider_id,
          account_id: account_id,
          message: message
        }.compact
      end

      response :created do
        structure = {
          object: String,
          invitation_id: String
        }

        body(**structure) do |res|
          if res.object == 'UserInvitationSent'
            :sent
          else
            :not_sent
          end
        end
      end

      response :bad_request do
        structure = {
          status: Integer,
          type: String,
          title: String,
          detail: String
        }

        body(**structure) do |res|
          case res[:type]
          when 'errors/already_invited_recently'
            :already_invited_recently
          else
            res[:type]
          end
        end
      end
    end

    path :user_id, is_param: true do
      root_method :get_user

      params do |account_id:|
        { account_id: }
      end

      response :ok do
        body(
          object: String,
          is_self: Purple::Boolean,
          headline: String,
          location: String,
          provider: String,
          websites: Array,
          birthdate: {
            day: { type: Integer, optional: true },
            month: { type: Integer, optional: true },
          },
          last_name: String,
          first_name: String,
          is_creator: Purple::Boolean,
          is_premium: Purple::Boolean,
          member_urn: String,
          provider_id: String,
          is_influencer: Purple::Boolean,
          follower_count: Integer,
          primary_locale: {
            country: String,
            language: String
          },
          is_open_profile: Purple::Boolean,
          is_relationship: Purple::Boolean,
          network_distance: String,
          connections_count: Integer,
          public_identifier: String,
        )
      end

      response :unprocessable_entity do
        structure = {
          status: Integer,
          type: String,
          title: String,
          detail: String
        }

        body(**structure) do |res|
          case res.type
          when 'errors/invalid_recipient'
            :not_found
          else
            res
          end
        end
      end

      response :not_found do
        body({}) do |_res|
          :not_found
        end
      end
    end
  end
end

RSpec.describe Unipile::Linkedin::PurpleClient do
  let(:resource) { double(:resource) }
  let(:headers) { {} }
  let(:connection) { double('connection') }

  before do
    allow(connection).to receive(:headers=) { |h| headers.merge!(h) }
    allow(Faraday).to receive(:new).and_yield(connection).and_return(connection)
  end

  describe '.linkedin_invite' do
    it 'returns :sent and triggers callback with headers' do
      response = instance_double(Faraday::Response,
                                 status: 201,
                                 body: { object: 'UserInvitationSent', invitation_id: '123' }.to_json)
      allow(connection).to receive(:post).and_return(response)

      expect(Events).to receive(:unipile).with(
        url: 'https://api4.unipile.com:13451/api/v1/users/invite',
        params: { provider_id: 1, account_id: 2, message: 'hi' },
        headers: hash_including('X-API-KEY' => 'secret'),
        response: { 'object' => 'UserInvitationSent', 'invitation_id' => '123' },
        resource: resource
      )

      result = described_class.linkedin_invite(provider_id: 1, account_id: 2, message: 'hi', resource: resource)

      expect(result).to eq(:sent)
      expect(headers['X-API-KEY']).to eq('secret')
    end
  end

  describe '.get_user' do
    it 'returns :not_found when recipient is invalid' do
      response = instance_double(Faraday::Response,
                                 status: 422,
                                 body: {
                                   status: 422,
                                   type: 'errors/invalid_recipient',
                                   title: 'Invalid recipient',
                                   detail: 'invalid'
                                 }.to_json)
      allow(connection).to receive(:get).and_return(response)

      result = described_class.get_user('77', account_id: 8, resource: resource)

      expect(result).to eq(:not_found)
    end
  end
end

