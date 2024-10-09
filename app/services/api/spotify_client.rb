# frozen_string_literal: true

module Api
  class SpotifyClient < Client
    if Rails.env.local?
      REDIRECT_URI = "http://localhost:3000/spotify_oauth/callback".freeze
    else
      raise NotImplementedError("Oauth redirect URI not defined.")
    end

    class << self
      def fetch_access_token(code)
        new.fetch_access_token(code)
      end

      def get_access_token
        new.get_access_token
      end
    end

    attr_reader :client_id, :client_secret

    def initialize
      @client_id = ENV["SPOTIFY_CLIENT_ID"]
      @client_secret = ENV["SPOTIFY_CLIENT_SECRET"]
    end

    # Returns a valid (not expired) access token object,
    # or nil if token refresh didn't succeed.
    def get_access_token
      access_token = OauthAccessToken.last
      if access_token&.expired?
        access_token = refresh_token(access_token)
      end
      access_token
    end

    def fetch_access_token(code)
      data = URI.encode_www_form({
                                   grant_type: "authorization_code",
                                   code: code,
                                   redirect_uri: REDIRECT_URI
                                 })
      response = request_token(data)
      if response.is_a?(Net::HTTPSuccess)
        data = JSON.parse(response.body)
        begin
          OauthAccessToken.create!(
            app: "spotify",
            access_token: data["access_token"],
            refresh_token: data["refresh_token"],
            expires_at: DateTime.now + data["expires_in"].seconds
          )
        rescue ActiveRecord::RecordInvalid
          Rails.logger.error("Failed to save the access token")
        end
      else
        log_response("Failed to authenticate", response, :error)
      end
    end

    def refresh_token(token)
      data = URI.encode_www_form({
                                   grant_type: "refresh_token",
                                   refresh_token: token.refresh_token
                                 })
      response = request_token(data)
      if response.is_a?(Net::HTTPSuccess)
        data = JSON.parse(response.body)
        begin
          token.update!(
            access_token: data["access_token"],
            refresh_token: data["refresh_token"] || token.refresh_token,
            expires_at: DateTime.now + data["expires_in"].seconds
          )
        rescue ActiveRecord::RecordInvalid
          Rails.logger.error("Failed to update the access token")
        end
      else
        log_response("Failed to revalidate the access token", response, :error)
      end
    end


    private

    def request_token(data)
      uri = URI("https://accounts.spotify.com/api/token")

      req = Net::HTTP::Post.new(uri)
      req.basic_auth(client_id, client_secret)
      req.content_type = "application/x-www-form-urlencoded"
      req.body = data
      Net::HTTP.start(uri.hostname, use_ssl: true) do |http|
        http.request(req)
      end
    end
  end
end
