defmodule GlitchWeb.Utils do
  alias GlitchWeb.HtmlSanitizer

  def to_html(markdown) do
    (markdown || "")
    |> String.trim()
    |> Earmark.as_html!(breaks: true)
    |> HtmlSanitizer.sanitize_html()
  end
end
