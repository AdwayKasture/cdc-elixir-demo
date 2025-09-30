import Config

config :cdc_wal, ecto_repos: [CdcWal.Repo]

config :cdc_wal, CdcWal.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "cdc_db",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10
