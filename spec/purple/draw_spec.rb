# frozen_string_literal: true

RSpec.describe '.draw' do
  it 'loads and evaluates DSL paths relative to the caller file' do
    expect(TimeMagic::Client.api.full_path).to eq(:api)
    expect(TimeMagic::Client.api.v1.full_path).to eq('api/v1')
    expect(TimeMagic::Client.api.v1.status.full_path).to eq('api/v1/status')
  end
end
