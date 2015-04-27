require 'uri'
require 'http'
require 'json'

module DoneWunder
  class Wunderlist
    Error = Class.new(StandardError)

    attr_reader :client_id, :client_secret, :access_token, :http

    def initialize(client_id, client_secret, access_token = nil)
      @client_id, @client_secret, @access_token = client_id, client_secret, access_token
      @http = HTTP.with_headers("X-Client-ID"    => client_id)
      @http = http.with_headers("X-Access-Token" => access_token) if access_token
    end

    def auth_endpoint(**params)
      params = URI.encode_www_form(params.merge(client_id: client_id))
      "https://www.wunderlist.com/oauth/authorize?#{params}"
    end

    def auth(code)
      result = HTTP.post('https://www.wunderlist.com/oauth/access_token',
                json: { client_id: client_id, client_secret: client_secret, code: code})
      raise Error, 'could not resolve access token' if result.status != 200

      token = JSON.load(result.to_s)['access_token']
      with_token(token)
    end

    def with_token(token)
      return self if access_token == token
      Wunderlist.new(client_id, client_secret, token)
    end

    def user
      @user ||= get(:user)
    end

    def lists
      @lists ||= get(:lists)
    end

    def name
      user['name']
    end

    def email
      user['email']
    end

    def user_id
      user['id']
    end

    def create_webhook(list, url, processor_type: 'generic', configuration: '')
      list = list['id'] if list.is_a? Hash
      post(:webhooks, list_id: Integer(list), url: url, processor_type: processor_type, configuration: configuration)
    end

    def delete_webook(id)
      # docs claim you need a revision, but suprise, you don't
      delete "webhooks/#{id}"
    end

    def request(method, path, **options)
      result  = http.public_send(method, "https://a.wunderlist.com/api/v1/#{path}", **options)
      payload = JSON.load(result.to_s)
      raise Error, error_message(result) if result.status / 100 != 2
      payload
    end

    def error_message(result)
      return "unknown error (status #{result.status})" unless result['error']
      result['error']['message']
    end

    def get(path, **params)
      request(:get, path, params: params)
    end

    def post(path, **params)
      request(:post, path, json: params)
    end

    def delete(path, **params)
      request(:delete, path, json: params)
    end
  end
end
