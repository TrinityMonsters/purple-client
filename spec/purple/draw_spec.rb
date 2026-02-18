# frozen_string_literal: true

RSpec.describe '.draw' do
  it 'loads and evaluates DSL paths relative to the caller file' do
    api_path = TimeMagic::Client.api
    v1_path = api_path.v1
    status_path = v1_path.children.find { |child| child.name == :status }

    expect(api_path.full_path).to eq(:api)
    expect(v1_path.full_path).to eq('api/v1')
    expect(status_path.full_path).to eq('api/v1/status')
  end
end
