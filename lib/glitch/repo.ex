defmodule Glitch.Repo do
  use Ecto.Repo,
    otp_app: :glitch,
    adapter: Ecto.Adapters.SQLite3
end
