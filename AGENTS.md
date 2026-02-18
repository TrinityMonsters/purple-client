# LLM Guide for Purple::Client Wrapper Clients

This repository uses **wrapper clients** built on `Purple::Client`. A wrapper client is a thin Ruby class that declaratively describes an API using the DSL (domain, paths, params, responses, and response schemas). The DSL then generates methods that perform HTTP requests and validate/shape responses.

**A wrapper client is NOT:**
- A generic HTTP client or SDK with its own request/response plumbing.
- A place for business logic, caching, retries, or complex data transformations.
- A replacement for application-level services or models.

## Golden path structure

When adding a new wrapper, follow this structure:

1. **Namespace + client class** (module name matches provider/service name)
2. **`domain`** declaration
3. **`path` tree** that mirrors API routes
4. **`params`** and request **`body`** definitions where applicable
5. **`response`** blocks for expected status codes
6. **`root_method`** for each callable endpoint

## Naming conventions

- `root_method` should be a **verb/action** (`convert`, `live_rates`, `historical_rates`).
- Parameter names should mirror the API parameter names. Ruby `snake_case` is fine—document any mapping or normalization if needed.

## Modeling guidelines

- **Query params**
  ```ruby
  params do |base:, symbols: nil|
    { base: base, symbols: symbols }.compact
  end
  ```

- **Request bodies**
  ```ruby
  params do |currency:, amount:|
    { currency: currency, amount: amount }
  end
  ```
  The hash returned by `params` becomes the JSON body for POST/PUT/PATCH. Use `body(...)` to describe **response** schemas.

- **Multiple responses**
  ```ruby
  response :ok do
    body(success: Purple::Boolean)
  end

  response :bad_request do
    body(error: { code: Integer, info: { type: String, allow_blank: true } })
  end
  ```

- **Optional / nullable fields**
  ```ruby
  body(
    message: { type: String, allow_blank: true },
    provider_id: { type: String, optional: true }
  )
  ```

- **Booleans**
  ```ruby
  body(success: Purple::Boolean)
  ```

- **Arrays**
  ```ruby
  body(:array_of, id: Integer, name: String)
  ```

- **Response transformation**
  ```ruby
  body(result: Float) { |res| res.result }
  ```


## Organizing wrappers with `draw`

Use `draw` to keep large wrappers readable by splitting DSL declarations into
smaller files.

```ruby
# clients/payments/client.rb
class Payments::Client < Purple::Client
  domain 'https://api.example.com'

  draw 'paths/invoices'
  draw 'paths/refunds.rb'
end

# clients/payments/paths/invoices.rb
path :invoices do
  response :ok do
    body :default
  end

  root_method :invoices
end
```

## DO / DON'T (for LLMs)

**DO**
- Use the DSL (`domain`, `path`, `params`, `response`, `body`, `root_method`).
- Describe response schemas explicitly, even if partial.
- Keep the wrapper thin; add only small response transformations.
- Validate responses with `body(...)` so downstream callers get consistent types.

**DON'T**
- Invent a generic HTTP client or bypass the DSL.
- Add business logic, persistence, or retries inside the wrapper.
- Skip response validation or return raw JSON when a schema is expected.

## Skeleton wrapper template (copy/paste)

```ruby
# frozen_string_literal: true

require "purple/client"

module ProviderName
  class Client < Purple::Client
    domain "https://api.provider.example"

    path :resource do
      params do |id:, verbose: nil|
        { id: id, verbose: verbose }.compact
      end

      response :ok do
        body(
          id: Integer,
          name: String,
          active: Purple::Boolean,
          metadata: {
            created_at: String,
            tags: { type: Array, optional: true }
          }
        )
      end

      response :bad_request do
        body(
          error: String,
          message: { type: String, allow_blank: true }
        )
      end

      root_method :fetch_resource
    end
  end
end
```
