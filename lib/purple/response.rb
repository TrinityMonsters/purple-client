# frozen_string_literal: true

# Implements basic response object
class Purple::Response
  extend Dry::Initializer[undefined: false]

  option :status
  option :path

  attr_accessor :body

  CODES = {
    ok: 200,
    bad_request: 400,
    unauthorized: 401,
    forbidden: 403,
    not_found: 404,
    too_many_requests: 429,
    internal_server_error: 500
  }.freeze

  def status_code
    CODES[@status]
  end
end
