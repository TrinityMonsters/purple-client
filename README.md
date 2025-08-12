# Purple::Client

Purple::Client is a small DSL that helps you describe HTTP APIs. You define a domain, paths, and response structures, and the library generates handy methods for interacting with your service.

## Installation

Add the gem to your project:

```bash
bundle add purple-client
```

Or install it manually with:

```bash
gem install purple-client
```

## Usage

Below are some basic examples of how to define requests and call them. Each
snippet defines a custom class that inherits from `Purple::Client`.

### Simple GET request

```ruby
class StatusClient < Purple::Client
  domain 'https://api.example.com'

  path :status do
    response :ok do
      body :default
    end
    root_method :status
  end
end

# Performs GET https://api.example.com/status
StatusClient.status
```

### Path with a dynamic parameter

```ruby
class JobsClient < Purple::Client
  domain 'https://api.example.com'

  path :jobs do
    path :job_id, is_param: true do
      response :ok do
        body id: Integer, name: String
      end
      root_method :job
    end
  end
end

# Performs GET https://api.example.com/jobs/123
JobsClient.job(123)
```

### Using authorization

```ruby
class ProfileClient < Purple::Client
  domain 'https://api.example.com'
  authorization :bearer, 'TOKEN'

  path :profile do
    response :ok do
      body :default
    end
    root_method :profile
  end
end

# Authorization header will be sent automatically
ProfileClient.profile
```

### Using custom headers

```ruby
class CustomHeadersClient < Purple::Client
  domain 'https://api.example.com'
  authorization :custom_headers,
                'X-API-KEY' => 'your-api-key',
                'X-Secret' => 'your-api-secret'

  path :widgets do
    response :ok do
      body :default
    end
    root_method :widgets
  end
end

# Custom headers will be sent automatically
CustomHeadersClient.widgets
```

### Nested paths

```ruby
class PostsClient < Purple::Client
  domain 'https://api.example.com'

  path :users do
    path :user_id, is_param: true do
      path :posts do
        response :ok do
          body [{ id: Integer, title: String }]
        end
        root_method :user_posts
      end
    end
  end
end

# Performs GET https://api.example.com/users/7/posts
PostsClient.user_posts(user_id: 7)
```

### Callbacks with additional arguments

```ruby
class EventsClient < Purple::Client
  domain 'https://api.example.com'

  additional_callback_arguments :resource

  callback do |url, params, headers, response, resource|
    StoreEvent.call(url:, params:, headers:, response:, resource:)
  end

  path :events do
    response :ok do
      body :default
    end
    root_method :events
  end
end

resource = SomeModel.find(1)
EventsClient.events(resource:)
```

`additional_callback_arguments` lets you specify parameter names that will be
extracted from the call and passed to your callback. In the example above the
`resource` keyword argument is removed from the request parameters, but is
available inside the callback so you can associate the stored event with a
record of your choice.

### Boolean response types

If you have boolean types `true` or `false` in your response, use
`Purple::Boolean` in the response configuration.

```ruby
class AccountsClient < Purple::Client
  domain 'https://api.example.com'

  path :accounts do
    response :ok do
      body(
        last_name: String,
        first_name: String,
        is_creator: Purple::Boolean,
        is_premium: Purple::Boolean,
      )
    end
    root_method :accounts
  end
end
```

### Optional fields

Sometimes an API response omits certain keys. You can mark those fields as
optional in the body definition so their absence doesn't raise validation errors.

```ruby
class CalendarClient < Purple::Client
  domain 'https://api.example.com'

  path :schedule do
    response :ok do
      body(
        day: { type: Integer, optional: true },
      )
    end
    root_method :schedule
  end
end

# The `day` attribute may be missing in the response
CalendarClient.schedule
```

### Allow blank fields

Some APIs return keys that are present but contain `null` or empty string values.
You can mark those fields with `allow_blank` so blank values do not raise
validation errors.

```ruby
class ProfilesClient < Purple::Client
  domain 'https://api.example.com'

  path :profile do
    response :ok do
      body(
        middle_name: { type: String, allow_blank: true },
      )
    end
    root_method :profile
  end
end

# The `middle_name` attribute may be blank or omitted in the response
ProfilesClient.profile
```

### Array responses

When an endpoint returns an array of objects, you can use `:array_of` to
describe the structure of each element in the array.

```ruby
class MerchantsClient < Purple::Client
  domain 'https://api.example.com'

  path :merchants do
    response :ok do
      structure = {
        id: Integer,
        name: String,
        address: String,
        work_time: String,
        accepts_qr: { type: String, optional: true }
      }

      body(:array_of, **structure)
    end
    root_method :merchants
  end
end

# Each array element will be validated against the structure
MerchantsClient.merchants
```

### Response body processing

After the body structure is validated, you can supply a block to `body`
to transform or handle the parsed response. This is useful for mapping
error payloads to simpler return values or for normalizing data.

```ruby
class MessagesClient < Purple::Client
  domain 'https://api.example.com'

  path :messages do
    response :unprocessable_entity do
      structure = {
        status: Integer,
        type: String,
        title: String,
        detail: String
      }

      body(**structure) do |res|
        case res.type
        when 'errors/invalid_recipient'
          :not_found
        else
          res
        end
      end
    end
    root_method :send_message
  end
end

# Returns :not_found when the recipient is invalid, otherwise returns the
# parsed response body.
MessagesClient.send_message
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then run
`rake spec` to execute the tests. You can also run `bin/console` for an interactive
prompt to experiment with the library.

To install this gem onto your local machine, run `bundle exec rake install`.
To release a new version, update the version number in `version.rb`, then run
`bundle exec rake release`.

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/[USERNAME]/purple-client. Contributors are expected to adhere
to the [code of conduct](https://github.com/[USERNAME]/purple-client/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the
[MIT License](https://opensource.org/licenses/MIT).

