defmodule GlitchWeb.HtmlSanitizer do
  @moduledoc """
  Module for sanitizing HTML used in chat.
  """
  alias GlitchWeb.DescriptionScrubber
  alias GlitchWeb.ChatScrubber
  alias HtmlSanitizeEx.Scrubber

  def sanitize_html_description(html) do
    Scrubber.scrub(html, DescriptionScrubber)
  end

  def sanitize_html_chat(html) do
    Scrubber.scrub(html, ChatScrubber)
  end
end
