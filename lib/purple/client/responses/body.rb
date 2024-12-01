# frozen_string_literal: true

require 'purple/client/responses'
require 'purple/client/responses/object'

class Purple::Client::Responses::Body
  extend Dry::Initializer[undefined: false]

  class BodyStructureMismatchError < StandardError
    def initialize(field, expected_type, actual_value, object)
      super("Field '#{field}' expected to be of type '#{expected_type}', but got '#{actual_value.class}' with value '#{actual_value}'.\nObject: #{object}")
    end
  end

  option :structure, default: -> { {} }
  option :response
  option :transform, optional: true, default: -> {}

  def validate!(body, arguments)
    parsed_body = JSON.parse(body, symbolize_names: true)

    result = if parsed_body.is_a? Integer
               parsed_body
             else
               underscored_body = if parsed_body.is_a? Array
                                    parsed_body.map { |item| item.transform_keys { |key| key.to_s.underscore.to_sym } }
                                  else
                                    parsed_body.transform_keys { |key| key.to_s.underscore.to_sym }
                                  end

               if underscored_body.is_a? Array
                 underscored_body.each do |item|
                   check_structure!(item)
                 end
               else
                 check_structure!(underscored_body)
               end

               if underscored_body.is_a?(Array)
                 underscored_body.map { |item| create_object(item) }
               else
                 create_object(underscored_body)
               end
             end

    if transform.is_a?(Proc)
      transform.call(result, arguments)
    else
      result
    end
  rescue JSON::ParserError => e
    raise ArgumentError, "Invalid JSON format: #{e.message}"
  end

  private

  def create_object(body)
    object = Class.new(Purple::Client::Responses::Object) do
      body.each do |key, value|
        define_method(key) { value }
      end
    end.new

    object.attributes = body

    object
  end

  def check_structure!(object, substructure = structure)
    substructure.each do |key, value|
      if value.is_a?(Hash)
        if value.key?(:optional) && value.key?(:type)
          next if value[:optional]

          check_type!(object, key, value[:type])
        else
          check_structure!(object[key], substructure[key])
        end
      else
        check_type!(object, key, value)
      end
    end
  end

  def check_type!(object, key, expected_type)
    unless object.key?(key)
      raise BodyStructureMismatchError.new(key, expected_type, object[key], object),
            "Missing field '#{key}' in response body. Body: #{object}"
    end

    return if object[key].is_a?(expected_type)

    raise BodyStructureMismatchError.new(key, expected_type, object[key], object)
  end
end
