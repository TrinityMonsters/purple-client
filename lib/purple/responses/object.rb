# frozen_string_literal: true

# Purple returns objects as responses from API. This is a base class for all responses objects.
require 'forwardable'

class Purple::Responses::Object
  extend Forwardable

  attr_accessor :attributes

  def_delegators :attributes, :to_s
end
