# frozen_string_literal: true

class Purple::Request
  extend Dry::Initializer[undefined: false]

  attr_accessor :params
end
