# frozen_string_literal: true

require 'dry-initializer'
require 'faraday'
require 'active_support/core_ext/hash/deep_merge'
require 'active_support/core_ext/object/inclusion'
require 'active_support/core_ext/object/blank'
require 'cgi'

module Purple
  class Path
    extend Dry::Initializer[undefined: false]

    option :client
    option :name
    option :parent
    option :is_param, default: -> { false }
    option :children, default: -> { [] }
    option :method, optional: true
    option :request, optional: true, default: -> { Purple::Request.new }
    option :responses, optional: true, default: -> { [] }

    def full_path
      if is_param
        CGI.escape(@param_value.to_s)
      else
        name
      end => current_path

      parent.nil? ? current_path : "#{parent.full_path}/#{current_path}"
    end

    def with(*args)
      @param_value = args.first
    end

    def method_missing(method_name, *args, **kw_args, &)
      if children.any? { |child| child.name == method_name }
        child = children.find { |child| child.name == method_name }

        if child.is_param
          child.with(*args)
        end

        if child.children.any?
          child
        else
          callback_arguments = client.additional_callback_arguments.map do |arg|
            kw_args.delete(arg)
          end

          child.execute(*args, *callback_arguments)
        end
      else
        super
      end
    end

    def execute(params = {}, args = {}, *callback_arguments)
      headers = {
        'Accept' => 'application/json',
        'Content-Type' => 'application/json'
      }

      if client.authorization
        authorization = client.authorization[:data].call

        headers.deep_merge!(authorization) if client.authorization[:type].in?(%i[bearer custom_headers])
        params.deep_merge!(authorization) if client.authorization[:type] == :custom_query
      end

      connection = Faraday.new(url: client.domain) do |conn|
        conn.options.timeout = client.timeout if client.timeout.present?
        conn.headers = headers
      end

      if client.domain.blank?
        raise ArgumentError, 'Client domain is not set. Please set the domain in the client configuration.'
      end

      unless client.domain.start_with?('http')
        raise ArgumentError, "Invalid URL: #{client.domain}. Ensure you have set protocol (http/https) in the client domain."
      end

      url = "#{client.domain}/#{full_path}"

      case method
      when :get
        connection.get(url, params)
      when :post
        connection.post(url, params.to_json)
      when :put
        connection.put(url, params.to_json)
      when :delete
        connection.delete(url, params)
      when :patch
        connection.patch(url, params.to_json)
      end => response

      resp_structure = responses.find { |resp| resp.status_code == response.status }

      if resp_structure.nil?
        raise "#{client.domain}/#{full_path} returns #{response.status}, but it is not defined in the client"
      else
        if response.body.blank? && !resp_structure.body.nil? && resp_structure.body != :default
          raise "#{client.domain}/#{full_path} returns empty body, but it is defined in the client. Do not define body for empty responses or set it to :default to skip validation.\n\nSee https://github.com/trinitymonsters/purple-client?tab=readme-ov-file#simple-get-request\n"
        end

        if resp_structure.body.is_a?(Purple::Responses::Body)
          resp_structure.body.validate!(response.body, args)
        elsif resp_structure.body == :default
          response.body
        else
          {}
        end => object

        raw_body = response.body.blank? ? {} : JSON.parse(response.body)

        client.callback&.call(url, params, headers, raw_body, *callback_arguments)

        if block_given?
          yield(resp_structure.status, object)
        else
          object
        end
      end
    end
  end
end
