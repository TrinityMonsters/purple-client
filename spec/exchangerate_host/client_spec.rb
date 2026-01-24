# frozen_string_literal: true

require "spec_helper"
require "webmock/rspec"
require_relative "../../examples/real_world/exchangerate_host/client"

RSpec.describe ExchangerateHost::Client do
  it "requests live rates with query params" do
    stub_request(:get, "https://api.exchangerate.host/latest")
      .with(query: { "base" => "USD", "symbols" => "EUR" })
      .to_return(
        status: 200,
        body: {
          success: true,
          base: "USD",
          date: "2024-01-01",
          rates: { "EUR" => 0.92 }
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    response = described_class.live(base: "USD", symbols: "EUR")

    expect(response.base).to eq("USD")
    expect(response.rates[:"EUR"]).to eq(0.92)
  end

  it "returns the converted amount from the transform block" do
    stub_request(:get, "https://api.exchangerate.host/convert")
      .with(query: { "from" => "USD", "to" => "EUR", "amount" => "10" })
      .to_return(
        status: 200,
        body: {
          success: true,
          query: { from: "USD", to: "EUR", amount: 10.0 },
          info: { rate: 0.92, timestamp: 1_700_000_000 },
          result: 9.2,
          date: "2024-01-01"
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    result = described_class.convert(from: "USD", to: "EUR", amount: 10)

    expect(result).to eq(9.2)
  end

  it "accepts blank error info on bad requests" do
    stub_request(:get, "https://api.exchangerate.host/latest")
      .with(query: { "base" => "USD" })
      .to_return(
        status: 400,
        body: {
          success: false,
          error: { code: 400, type: "invalid_base", info: nil }
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    response = described_class.live(base: "USD")

    expect(response.error[:type]).to eq("invalid_base")
    expect(response.error[:info]).to be_nil
  end
end
