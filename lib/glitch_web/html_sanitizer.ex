defmodule GlitchWeb.HtmlSanitizer do
  alias GlitchWeb.Scrubber, as: GlitchScrubber
  alias HtmlSanitizeEx.Scrubber

  def sanitize_html(html) do
    Scrubber.scrub(html, GlitchScrubber)
  end
end
