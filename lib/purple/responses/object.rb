# frozen_string_literal: true

# Purple returns objects as responses from API. This is a base class for all responses objects.
require 'active_support/core_ext/module/delegation'
class Purple::Responses::Object
  attr_accessor :attributes

  delegate :to_s, :[], to: :attributes

  def contain?(key)
    attributes.key?(key.to_sym) || attributes.key?(key.to_s)
  end
end
