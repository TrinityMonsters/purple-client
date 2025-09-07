require 'spec_helper'
require 'json'

RSpec.describe Purple::Responses::Body do
  let(:structure) do
    {
      name: String,
      day: { type: Integer, optional: true }
    }
  end

  context 'when optional field is missing' do
    let(:body) { { name: 'John' }.to_json }
    subject(:response) { described_class.new(structure:, response: nil).validate!(body, {}) }

    it 'returns false for contain? on the missing field' do
      expect(response.contain?(:day)).to eq(false)
      expect(response.contain?('day')).to eq(false)
    end

    it 'raises NoMethodError when accessing the missing optional field' do
      expect { response.day }.to raise_error(
        NoMethodError,
        "Optional field 'day' is not present in the response body. Use `contain?(:day)` to check its presence."
      )
    end
  end

  context 'when optional field is present' do
    let(:body) { { name: 'John', day: 15 }.to_json }
    subject(:response) { described_class.new(structure:, response: nil).validate!(body, {}) }

    it 'allows access to the field and contain? returns true' do
      expect(response.day).to eq(15)
      expect(response.contain?(:day)).to eq(true)
      expect(response.contain?('day')).to eq(true)
    end
  end
end
