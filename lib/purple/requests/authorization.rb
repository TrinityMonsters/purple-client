# frozen_string_literal: true

module Purple
  module Requests
    class Authorization
      class << self
        def bearer_token(value)
          {
            type: :bearer,
            data: lambda do
              { Authorization: "Bearer #{value}" }
            end
          }
        end

        def google_auth(credentials:, product:)
          auth_scope = case product
                       when :firebase
                         'firebase.messaging'
                       end

          {
            type: :google_auth,
            data: lambda do
              authorizer = Google::Auth::ServiceAccountCredentials.make_creds(
                json_key_io: StringIO.new(credentials),
                scope: "https://www.googleapis.com/auth/#{auth_scope}"
              )

              access_token = authorizer.fetch_access_token!
              bearer_token access_token['access_token']
            end
          }
        end

        def custom_headers(headers)
          {
            type: :custom_headers,
            data: lambda do
              headers
            end
          }
        end

        def custom_query(headers)
          {
            type: :custom_query,
            data: lambda do
              headers
            end
          }
        end
      end
    end
  end
end
