# frozen_string_literal: true

require "purple/client"

module ExchangerateHost
  class Client < Purple::Client
    domain "https://api.exchangerate.host"

    path :latest do
      params do |base: "USD", symbols: nil|
        { base: base, symbols: symbols }.compact
      end

      response :ok do
        body(
          success: Purple::Boolean,
          base: String,
          date: String,
          rates: { type: Hash, allow_blank: true }
        )
      end

      response :bad_request do
        body(
          success: Purple::Boolean,
          error: {
            code: Integer,
            type: String,
            info: { type: String, allow_blank: true }
          }
        )
      end

      root_method :live
    end

    path :historical do
      path :date, is_param: true do
        params do |base: nil, symbols: nil|
          { base: base, symbols: symbols }.compact
        end

        response :ok do
          body(
            success: Purple::Boolean,
            base: String,
            date: String,
            rates: { type: Hash, allow_blank: true }
          )
        end

        response :bad_request do
          body(
            success: Purple::Boolean,
            error: {
              code: Integer,
              type: String,
              info: { type: String, allow_blank: true }
            }
          )
        end

        root_method :historical
      end
    end

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
          info: {
            rate: Float,
            timestamp: { type: Integer, optional: true }
          },
          result: Float,
          date: String
        ) { |res| res.result }
      end

      response :unprocessable_entity do
        body(
          success: Purple::Boolean,
          error: {
            code: Integer,
            type: String,
            info: { type: String, allow_blank: true }
          }
        )
      end

      root_method :convert
    end

    path :timeframe do
      params do |start_date:, end_date:, base: nil, symbols: nil|
        {
          start_date: start_date,
          end_date: end_date,
          base: base,
          symbols: symbols
        }.compact
      end

      response :ok do
        body(
          success: Purple::Boolean,
          timeseries: Purple::Boolean,
          start_date: String,
          end_date: String,
          base: String,
          rates: { type: Hash, allow_blank: true }
        )
      end

      response :bad_request do
        body(
          success: Purple::Boolean,
          error: {
            code: Integer,
            type: String,
            info: { type: String, allow_blank: true }
          }
        )
      end

      root_method :timeframe
    end
  end
end
