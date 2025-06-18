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

Below are some basic examples of how to define requests and call them.

### Simple GET request

```ruby
Purple::Client.domain 'https://api.example.com'

Purple::Client.path :status do
  response :ok do
    body :default
  end
  root_method :status
end

# Performs GET https://api.example.com/status
Purple::Client.status
```

### Path with a dynamic parameter

```ruby
Purple::Client.path :jobs do
  path :job_id, is_param: true do
    response :ok do
      body id: Integer, name: String
    end
    root_method :job
  end
end

# Performs GET https://api.example.com/jobs/123
Purple::Client.job(job_id: 123)
```

### Using authorization

```ruby
Purple::Client.authorization :bearer, 'TOKEN'

Purple::Client.path :profile do
  response :ok do
    body :default
  end
  root_method :profile
end

# Authorization header will be sent automatically
Purple::Client.profile
```

### Nested paths

```ruby
Purple::Client.path :users do
  path :user_id, is_param: true do
    path :posts do
      response :ok do
        body [{ id: Integer, title: String }]
      end
      root_method :user_posts
    end
  end
end

# Performs GET https://api.example.com/users/7/posts
Purple::Client.user_posts(user_id: 7)
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

