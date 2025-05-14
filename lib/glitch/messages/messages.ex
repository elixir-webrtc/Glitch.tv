defmodule Glitch.Messages.Message do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  schema "messages" do
    field :author, :string
    field :body, :string
    field :flagged, :boolean

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(recording, attrs) do
    recording
    |> cast(attrs, [
      :author,
      :body,
      :flagged
    ])
    |> validate_required([
      :author,
      :body,
      :flagged
    ])
  end
end
