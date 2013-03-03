keys = load_yaml('keys')

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :ravelry, keys["ravelry"]["access_key"], keys["ravelry"]["secret_key"]
end
