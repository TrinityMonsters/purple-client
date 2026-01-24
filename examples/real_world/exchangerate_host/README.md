# Exchangerate Host Wrapper Example

This example shows a minimal, realistic wrapper client for [exchangerate.host](https://exchangerate.host) using `Purple::Client`.

It demonstrates:
- Multiple endpoints (`live`, `historical`, `convert`, `timeframe`)
- Required and optional params
- Nested response structures
- `optional` and `allow_blank`
- `Purple::Boolean`
- A small response transformation for `convert`

## Setup

From the repo root:

```bash
bundle install
```

## Run locally (optional live calls)

These examples perform live HTTP requests. If you are offline, skip them and rely on the specs.

```bash
ruby -r "./examples/real_world/exchangerate_host/client" -e "puts ExchangerateHost::Client.live(base: 'USD', symbols: 'EUR').rates[:eur]"

ruby -r "./examples/real_world/exchangerate_host/client" -e "puts ExchangerateHost::Client.historical('2020-01-01', base: 'USD', symbols: 'EUR').rates[:eur]"

ruby -r "./examples/real_world/exchangerate_host/client" -e "puts ExchangerateHost::Client.convert(from: 'USD', to: 'EUR', amount: 10)"

ruby -r "./examples/real_world/exchangerate_host/client" -e "puts ExchangerateHost::Client.timeframe(start_date: '2020-01-01', end_date: '2020-01-05', base: 'USD').rates.keys"
```

## Expected response shapes

```ruby
ExchangerateHost::Client.live(base: "USD", symbols: "EUR")
# => #<Purple::Responses::Object ...>
# response.base #=> "USD"
# response.rates[:"EUR"] #=> 0.92

ExchangerateHost::Client.historical("2020-01-01", base: "USD", symbols: "EUR")
# => #<Purple::Responses::Object ...>

ExchangerateHost::Client.convert(from: "USD", to: "EUR", amount: 10)
# => 9.2 (Float)

ExchangerateHost::Client.timeframe(start_date: "2020-01-01", end_date: "2020-01-05", base: "USD")
# => #<Purple::Responses::Object ...>
```
