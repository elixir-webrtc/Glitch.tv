defmodule Glitch.FeatureFlags do
  @moduledoc """
  Module managing all feature flags used by the application.
  """
  @spec recordings_enabled() :: boolean()
  def recordings_enabled() do
    Application.fetch_env!(:glitch, :enable_recordings)
  end

  @spec share_button_enabled() :: boolean()
  def share_button_enabled() do
    Application.fetch_env!(:glitch, :enable_share_button)
  end

  @spec elixirconf_links_enabled() :: boolean()
  def elixirconf_links_enabled() do
    Application.fetch_env!(:glitch, :enable_elixirconf_links)
  end
end
