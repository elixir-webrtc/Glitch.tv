defmodule Glitch.Messages do
  @moduledoc """
  The Messages context.
  """

  import Ecto.Query, warn: false
  alias Glitch.Repo

  alias Glitch.Messages.Message

  @doc """
  Returns the list of messages.

  ## Examples

      iex> list_messages()
      [%Message{}, ...]

  """
  def list_messages do
    Repo.all(Message)
  end

  def list_last_50_messages do
    inner_query =
      from m in Message,
        where: m.inserted_at >= ^DateTime.add(DateTime.utc_now(), -15, :minute),
        order_by: [desc: m.inserted_at],
        limit: 50

    query =
      from m in subquery(inner_query),
        order_by: [asc: m.inserted_at]

    Repo.all(query)
  end

  @doc """
  Gets a single Message.

  Raises `Ecto.NoResultsError` if the Message does not exist.

  ## Examples

      iex> get_message!(123)
      %Message{}

      iex> get_message!(456)
      ** (Ecto.NoResultsError)

  """
  def get_message!(id), do: Repo.get!(Message, id)

  @doc """
  Creates a Message.

  ## Examples

      iex> create_message(%{field: value})
      {:ok, %Message{}}

      iex> create_message(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_message(attrs \\ %{}) do
    %Message{}
    |> Message.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a Message.

  ## Examples

      iex> update_message(Message, %{field: new_value})
      {:ok, %Message{}}

      iex> update_message(Message, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_message(%Message{} = message, attrs) do
    message
    |> Message.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Message.

  ## Examples

      iex> delete_message(Message)
      {:ok, %Message{}}

      iex> delete_message(Message)
      {:error, %Ecto.Changeset{}}

  """
  def delete_message(%Message{} = message) do
    Repo.delete(message)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking Message changes.

  ## Examples

      iex> change_message(Message)
      %Ecto.Changeset{data: %Message{}}

  """
  def change_message(%Message{} = message, attrs \\ %{}) do
    Message.changeset(message, attrs)
  end
end
