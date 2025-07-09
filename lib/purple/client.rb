# frozen_string_literal: true

require 'purple/path'
require 'purple/request'
require 'purple/requests/authorization'
require 'purple/response'
require 'purple/responses/body'
require 'purple/boolean'
require_relative 'version'
require_relative 'client/version'

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

        define_singleton_method method_name do |*call_args, **kw_args, &block|
          if current_path.is_param
            value = call_args.first
            current_path.with(value)
          end

          callback_arguments = additional_callback_arguments.map do |arg|
            kw_args.delete(arg)
          end

          params = current_path.request.params.call(**kw_args) if current_path.request.params.is_a?(Proc)

          current_path.execute(params, kw_args, *callback_arguments, &block)
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

      def additional_callback_arguments(*array)
        if array.empty?
          @additional_callback_arguments || []
        else
          @additional_callback_arguments = array
        end
      end
    end
  end
end
