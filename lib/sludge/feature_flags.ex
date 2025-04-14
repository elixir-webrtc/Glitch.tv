defmodule Sludge.FeatureFlags do
  @spec recordings_enabled() :: boolean()
  def recordings_enabled() do
    Application.fetch_env!(:sludge, :enable_recordings)
  end
end
