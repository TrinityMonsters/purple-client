# frozen_string_literal: true

# Purple returns objects as responses from API. This is a base class for all responses objects.
class Purple::Responses::Object
  attr_accessor :attributes

  delegate :to_s, to: :attributes
end
