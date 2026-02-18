# frozen_string_literal: true

RSpec.describe '.draw' do
  it 'loads nested paths from external file into current path scope' do
    api_path = TimeMagic::Client.api

    expect(api_path.children.map(&:name)).to include(:v1)
    expect(api_path.v1.children.map(&:name)).to include(:status)
  end
end
