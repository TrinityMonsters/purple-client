# Testing Wrapper Clients with RSpec + WebMock

This guide shows how to test Purple::Client wrappers using **RSpec** and **WebMock** (no VCR).

## Setup

Add WebMock to your development/test dependencies (already included in this repo's Gemfile):

```ruby
# Gemfile
 gem "webmock", "~> 3.0"
```

In your spec file, require WebMock and stub HTTP calls:

```ruby
require "spec_helper"
require "webmock/rspec"
```

## Example spec

```ruby
# spec/exchangerate_host/client_spec.rb
require "spec_helper"
require "webmock/rspec"
require "examples/real_world/exchangerate_host/client"

RSpec.describe ExchangerateHost::Client do
  it "calls the live rates endpoint with query params" do
    stub_request(:get, "https://api.exchangerate.host/latest")
      .with(query: { "base" => "USD", "symbols" => "EUR" })
      .to_return(
        status: 200,
        body: {
          success: true,
          base: "USD",
          date: "2024-01-01",
          rates: { EUR: 0.92 }
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    response = described_class.live(base: "USD", symbols: "EUR")

    expect(response.base).to eq("USD")
    expect(response.rates[:"EUR"]).to eq(0.92)
  end

  it "validates non-:ok responses" do
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
  end
end
```

## What to assert

- **HTTP method + URL + query params** via `stub_request(...).with(...)`.
- **Response parsing and validation** by asserting fields defined in `body(...)`.
- **Non-:ok responses** by stubbing other status codes (`:bad_request`, `:unprocessable_entity`).
- **Optional/blank fields** by stubbing missing or `null` values and ensuring no validation errors.

## Running the tests

```bash
bundle exec rspec
```
