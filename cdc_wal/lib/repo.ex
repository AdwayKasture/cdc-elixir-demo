defmodule CdcWal.Repo do
  use Ecto.Repo,
    otp_app: :cdc_wal,
    adapter: Ecto.Adapters.Postgres
end
