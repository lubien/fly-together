defmodule FlyTogether.Repo do
  use Ecto.Repo,
    otp_app: :fly_together,
    adapter: Ecto.Adapters.Postgres
end
