defmodule GlitchWeb.Utils do
  @moduledoc """
  Module for utilities used across whole project.
  """
  alias GlitchWeb.HtmlSanitizer

  def to_html_chat(markdown) do
    (markdown || "")
    |> String.trim()
    |> Earmark.as_html!(breaks: true)
    |> HtmlSanitizer.sanitize_html_chat()
  end

  def to_html_description(markdown) do
    (markdown || "")
    |> String.trim()
    |> Earmark.as_html!(breaks: true)
    |> HtmlSanitizer.sanitize_html_description()
  end

  def to_text(markdown) do
    (markdown || "")
    |> Earmark.as_html!(breaks: true)
    |> HtmlSanitizeEx.strip_tags()
    |> String.trim()
  end
end
