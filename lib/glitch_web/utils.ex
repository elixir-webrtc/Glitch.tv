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
    |> transform_html()
  end

  def to_text(markdown) do
    (markdown || "")
    |> Earmark.as_html!(breaks: true)
    |> HtmlSanitizeEx.strip_tags()
    |> String.trim()
  end

  defp transform_html(raw_html) do
    {:ok, document} = Floki.parse_document(raw_html)

    document
    |> Floki.traverse_and_update(fn
      {"a", attrs, children} -> {"a", attrs ++ [{"target", "_blank"}], children}
      other -> other
    end)
    |> Floki.raw_html()
  end
end
