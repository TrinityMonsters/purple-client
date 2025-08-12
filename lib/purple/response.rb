# frozen_string_literal: true

# Implements basic response object
class Purple::Response
  extend Dry::Initializer[undefined: false]

  option :status
  option :path

  attr_accessor :body

  CODES = {
    ok: 200,
    created: 201,
    accepted: 202,
    bad_request: 400,
    unauthorized: 401,
    unprocessable_entity: 422,
    forbidden: 403,
    not_found: 404,
    too_many_requests: 429,
    internal_server_error: 500,
    gateway_timeout: 504,
  }.freeze

  def status_code
    CODES[@status]
  end
end
