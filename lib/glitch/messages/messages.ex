defmodule Glitch.Messages.Message do
  use Ecto.Schema
  import Ecto.Changeset

  schema "messages" do
    field :timestamp, :utc_datetime
    field :author, :string
    field :body, :string
    field :flagged, :boolean

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(recording, attrs) do
    recording
    |> cast(attrs, [
      :timestamp,
      :author,
      :body,
      :flagged
    ])
    |> validate_required([
      :timestamp,
      :author,
      :body,
      :flagged
    ])
  end
end
