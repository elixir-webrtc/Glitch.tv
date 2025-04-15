defmodule Glitch.FeatureFlags do
  @spec recordings_enabled() :: boolean()
  def recordings_enabled() do
    Application.fetch_env!(:glitch, :enable_recordings)
  end
end
