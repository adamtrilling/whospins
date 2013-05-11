require 'omniauth_ravelry'

keys = load_yaml('keys')

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :ravelry, keys["ravelry"]["access_key"], keys["ravelry"]["secret_key"]
  provider :google_oauth2, keys["google"]["access_key"], keys["google"]["secret_key"]
end
