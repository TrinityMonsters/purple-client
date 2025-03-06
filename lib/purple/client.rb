# frozen_string_literal: true

require 'purple/path'
require 'purple/request'
require 'purple/requests/authorization'
require 'purple/response'
require 'purple/responses/body'
require_relative "version"

module Purple
  class Client
    class << self
      def domain(value = nil)
        if value.nil?
          @domain
        else
          @domain = value
        end
      end

      def authorization(type = nil, value = nil, **custom_options)
        if type.nil? && value.nil? && custom_options.empty?
          @authorization
        else
          @authorization = case type
                           when :bearer
                             Purple::Requests::Authorization.bearer_token(value)
                           when :google_auth
                             Purple::Requests::Authorization.google_auth(**custom_options)
                           when :custom_headers
                             Purple::Requests::Authorization.custom_headers(custom_options)
                           when :custom_query
                             Purple::Requests::Authorization.custom_query(custom_options)
                           end
        end
      end

      def callback(&block)
        if block_given?
          @callback = block
        else
          @callback
        end
      end

      def path(name, method: :get, is_param: false)
        path = Path.new(name:, parent: @parent_path, method:, client: self, is_param:)

        @paths ||= []
        @paths << path

        @parent_path.children << path if @parent_path

        if block_given?
          @parent_path = path
          yield
        end

        @parent_path = path.parent
      end

      def root_method(method_name)
        current_path = @parent_path

        define_singleton_method method_name do |**args, &block|
          params = current_path.request.params.call(**args) if current_path.request.params.is_a?(Proc)

          current_path.execute(params, args, &block)
        end
      end

      def request
        yield if block_given?
      end

      def params(*args, &block)
        @parent_path.request.params = if block_given?
                                        block
                                      else
                                        args
                                      end
      end

      def response(status)
        resp = Response.new(status:, path: @parent_path)

        @parent_path.responses << resp
        @current_resp = resp

        yield if block_given?
      end

      def body(type = nil, **structure, &block)
        case type
        when :default
          @current_resp.body = :default
        else
          @current_resp.body = Responses::Body.new(structure:, response: @current_resp, transform: block)
        end
      end

      def method_missing(method_name, *args, &)
        if @paths&.any? { |path| path.name == method_name }
          @paths.find { |path| path.name == method_name }
        else
          super
        end
      end
    end
  end
end
