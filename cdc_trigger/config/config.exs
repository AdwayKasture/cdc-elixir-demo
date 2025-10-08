import Config

config :cdc_trigger, ecto_repos: [CdcTrigger.Repo]

config :cdc_trigger, CdcTrigger.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "cdc_db",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10
