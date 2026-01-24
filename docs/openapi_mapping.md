# OpenAPI → Purple::Client DSL Mapping

This guide shows how to translate common OpenAPI concepts into Purple::Client DSL constructs.

## Mapping overview

| OpenAPI concept | Purple::Client DSL |
| --- | --- |
| Path + HTTP method | `path :resource, method: :get` (nested paths reflect URL segments) |
| Query parameters | `params do |...| ... end` |
| Request body schema | Use `params` to build the request payload (for POST/PUT/PATCH, the hash returned by `params` becomes the JSON body). Use `body(...)` only for response schemas. |
| Response codes | `response :ok`, `response :bad_request`, `response :unprocessable_entity`, etc. |
| JSON object schema | `body(field: Type, nested: { ... })` |
| Arrays | `body(:array_of, id: Integer, name: String)` |
| Optional fields | `field: { type: String, optional: true }` |
| Nullable / blank | `field: { type: String, allow_blank: true }` |
| Boolean | `Purple::Boolean` |

## Worked example

### OpenAPI snippet

```yaml
paths:
  /convert:
    get:
      parameters:
        - in: query
          name: from
          schema: { type: string }
          required: true
        - in: query
          name: to
          schema: { type: string }
          required: true
        - in: query
          name: amount
          schema: { type: number }
          required: true
      responses:
        "200":
          description: Conversion result
          content:
            application/json:
              schema:
                type: object
                properties:
                  success: { type: boolean }
                  query:
                    type: object
                    properties:
                      from: { type: string }
                      to: { type: string }
                      amount: { type: number }
                  result: { type: number }
        "400":
          description: Bad request
```

### Purple::Client DSL

```ruby
class ExampleClient < Purple::Client
  domain "https://api.example.com"

  path :convert do
    params do |from:, to:, amount:|
      { from: from, to: to, amount: amount }
    end

    response :ok do
      body(
        success: Purple::Boolean,
        query: {
          from: String,
          to: String,
          amount: Float
        },
        result: Float
      )
    end

    response :bad_request

    root_method :convert
  end
end
```

### Notes

- Query params are produced by `params` (even for GET requests).
- Use `Purple::Boolean` for booleans, and `allow_blank` for fields that can be `null` or empty.
- For arrays, use `body(:array_of, ...)` with the element structure.
