class OauthAccessToken < ApplicationRecord
  def expired?
    DateTime.now > expires_at
  end
end
