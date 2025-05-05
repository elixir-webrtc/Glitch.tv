defmodule GlitchWeb.HtmlSanitizer do
  @moduledoc """
  Module for sanitizing HTML used in chat.
  """
  alias GlitchWeb.Scrubber, as: GlitchScrubber
  alias HtmlSanitizeEx.Scrubber

  def sanitize_html(html) do
    Scrubber.scrub(html, GlitchScrubber)
  end
end
