import Config

config :waffle,
  bucket: {:system, "WAFFLE_BUCKET"},
  storage: Waffle.Storage.Google.CloudStorage,
  token_fetcher: Waffle.GothTokenFetcher,
  goth_name: {:system, "WAFFLE_GOTH_NAME"}

config :goth, json: {:system, "GCP_CREDENTIALS"}
