require 'rails_helper'

RSpec.describe "SpotifyOauth Request", type: :request do
  let(:user) { create(:user) }

  describe "spotify_oauth#request_authorization" do
    it "redirects to spotify's authorization page" do
      get api_v1_spotify_oauth_request_authorization_path

      expect(response).to have_http_status(:redirect)
      expect(response.location).to match(/https:\/\/accounts.spotify.com\/authorize/)
    end
  end

  describe "spotify_oauth#callback" do
    context "when the authorization was not granted" do
      it "returns unauthorized error" do
        get api_v1_spotify_oauth_callback_path(error: "Some error message")

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when the authorization code is missing" do
      it "returns unauthorized error" do
        get api_v1_spotify_oauth_callback_path

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when authorization succeeds" do
      let(:oauth_access_token) { create(:oauth_access_token) }
      let(:authorization_code) { "valid_code" }
      let(:redirect_url) { api_v1_spotify_oauth_callback_url }
      let(:encoded_access_token) { "encoded_token" }
      let(:mocked_frontend_url) { "http://localhost" }

      before do
        allow(::Api::SpotifyClient).to receive(:fetch_access_token)
                                         .with(authorization_code, redirect_url)
                                         .and_return(oauth_access_token)
        allow(::Api::SpotifyClient).to receive(:fetch_user_info)
                                         .with(oauth_access_token)
                                         .and_return(user)
        allow(Rails.application.config).to receive(:frontend_url)
                                             .and_return(mocked_frontend_url)
        allow(JwtService).to receive(:encode)
                               .and_return(encoded_access_token)
      end

      it "redirects to the frontend" do
        get api_v1_spotify_oauth_callback_path(code: authorization_code)

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to("#{mocked_frontend_url}#access_token=#{encoded_access_token}")

        expect(::Api::SpotifyClient).to have_received(:fetch_access_token).with(authorization_code, redirect_url)
        expect(::Api::SpotifyClient).to have_received(:fetch_user_info).with(oauth_access_token)
      end
    end
  end
end
