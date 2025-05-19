defimpl Jason.Encoder, for: Glitch.Messages.Message do
  def encode(value, opts) do
    map = Map.take(value, [:id, :body, :author, :inserted_at, :flagged])

    Jason.Encode.map(map, opts)
  end
end
