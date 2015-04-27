require 'uri'
require 'http'
require 'json'

module DoneWunder
  class DoneThis
    Error = Class.new(StandardError)
    attr_reader :access_token, :http

    def initialize(access_token)
      @access_token = access_token
      @http         = HTTP.with_headers("Authorization" => "token #{access_token}")
    end

    def ok?
      request(:get, :noop, raise_error: false)['ok']
    end

    def teams
      @teams ||= get(:teams, page_size: 100)['results']
    end

    def done(item, short_name, done_date = nil, **meta_data)
      payload             = { raw_text: item, team: short_name }
      payload[:done_date] = done_date         if done_date
      payload[:meta_data] = meta_data.to_json if meta_data.any?
      post(:dones, **payload)
    end

    def request(method, path, raise_error: true, **options)
      result  = http.public_send(method, "https://idonethis.com/api/v0.1/#{path}/", **options)
      payload = (JSON.load(result.to_s) rescue { 'ok' => false })
      raise Error, error_for(payload) if raise_error and not payload['ok']
      payload
    end

    def error_for(payload)
      message = payload['detail'] || 'unknown error'
      if payload['errors']
        messages = payload['errors'].map { |f, m| "#{f}: #{m.join(', ')}" }
        message += " (#{messages.join('; ')})"
      end
      message
    end

    def get(path, **params)
      request(:get, path, params: params)
    end

    def post(path, **params)
      request(:post, path, form: params)
    end
  end
end
