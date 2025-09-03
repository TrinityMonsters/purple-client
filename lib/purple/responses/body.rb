# frozen_string_literal: true

require 'purple/responses'
require 'purple/responses/object'
require "active_support/core_ext/string/inflections"

class Purple::Responses::Body
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
    raise ArgumentError, "Invalid JSON format: #{e.message}. Body: #{body.inspect}"
  end

  private

  def create_object(body)
    object = Class.new(Purple::Responses::Object) do
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
        if options?(value)
          next if value[:optional]
          next if value[:allow_blank] && object[key].blank?

          check_type!(object, key, value[:type])
        else
          next if object[key].nil?

          check_structure!(object[key], substructure[key])
        end
      elsif value.is_a?(Array)
        if object[key].nil?
          raise BodyStructureMismatchError.new(key, value, nil, object),
            "Expected a non-nil array for '#{key}' in response body.\n\nExpected response structure: #{substructure}.\n\nUse '#{key}: { type: #{value}, allow_blank: true }' if this field can be nil."
        end

        type = value.first

        if type.is_a?(Symbol)
          raise "Body structure definition error in key '#{key}' of structure #{substructure}."
        end

        object[key].each_with_index do |item, index|
          if type.is_a?(Class)
            unless item.is_a?(type)
              raise BodyStructureMismatchError.new(key, type, item, object),
                "Expected item at #{index} index of '#{key}' to be of type '#{value[index]}', but got '#{item.class}' with value '#{item}'."
            end
          else
            check_structure!(item, type)
          end
        end
      else
        if object.nil?
          raise BodyStructureMismatchError.new(key, value, nil, object),
            "Expected a non-nil value for '#{key}' in response body. Expected response structure: #{substructure}"
        else
          check_type!(object, key, value)
        end
      end
    end
  end

  def check_type!(object, key, expected_type)
    return if key.in?([:optional, :allow_blank])

    unless object.key?(key)
      raise BodyStructureMismatchError.new(key, expected_type, object[key], object),
        "Missing field '#{key}' in response body. Body: #{object}\n\nUse '#{key}: { type: #{expected_type}, optional: true }' if this field may be absent."
    end

    return if expected_type == Purple::Boolean && (object[key] == true || object[key] == false)

    return if object[key].is_a?(expected_type)

    raise BodyStructureMismatchError.new(key, expected_type, object[key], object)
  end

  def options?(hash)
    hash.key?(:type) && (hash.key?(:optional) || hash.key?(:allow_blank))
  end
end
