defmodule Glitch.Repo.Migrations.CreateMessages do
  use Ecto.Migration

  def change do
    create table(:messages) do
      add :author, :string
      add :body, :string
      add :flagged, :boolean

      timestamps(type: :utc_datetime)
    end
  end
end
