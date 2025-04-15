defmodule GlitchWeb.Utils do
  def to_html(markdown) do
    (markdown || "")
    |> String.trim()
    |> Earmark.as_html!(breaks: true)
    |> HtmlSanitizeEx.basic_html()
  end
end
