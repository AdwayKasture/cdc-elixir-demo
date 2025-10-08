defmodule CdcTrigger.Repo do
  use Ecto.Repo,
    otp_app: :cdc_trigger,
    adapter: Ecto.Adapters.Postgres
end
