class CreateOauthAccessTokens < ActiveRecord::Migration[7.2]
  def change
    create_table :oauth_access_tokens do |t|
      t.string :app, null: false
      t.string :access_token, null: false, index: { unique: true }
      t.string :refresh_token, null: false, index: { unique: true }
      t.datetime :expires_at, null: false

      t.timestamps
    end
  end
end
