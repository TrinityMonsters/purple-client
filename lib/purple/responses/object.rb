# frozen_string_literal: true

# Purple returns objects as responses from API. This is a base class for all responses objects.
class Purple::Responses::Object
  attr_accessor :attributes

  # Avoid ActiveSupport dependency by manually delegating `to_s`
  def to_s
    attributes.to_s
  end
end
