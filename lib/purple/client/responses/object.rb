# frozen_string_literal: true

# Purple::Client returns objects as responses from API. This is a base class for all responses objects.
class Purple::Client::Responses::Object
  attr_accessor :attributes

  delegate :to_s, to: :attributes
end
