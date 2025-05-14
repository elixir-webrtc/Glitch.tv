defmodule GlitchWeb.Utils do
  @moduledoc """
  Module for utilities used across whole project.
  """
  alias GlitchWeb.HtmlSanitizer

  def to_html(markdown) do
    (markdown || "")
    |> String.trim()
    |> Earmark.as_html!(breaks: true)
    |> HtmlSanitizer.sanitize_html()
  end

  def to_text(markdown) do
    (markdown || "")
    |> Earmark.as_html!(breaks: true)
    |> HtmlSanitizeEx.strip_tags()
    |> String.trim()
  end
end
