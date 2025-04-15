defmodule GlitchWeb.RecordingLive.FormComponent do
  use GlitchWeb, :live_component

  alias Glitch.Recordings

  defp save_recording(socket, :new, recording_params) do
    case Recordings.create_recording(recording_params) do
      {:ok, recording} ->
        notify_parent({:saved, recording})

        {:noreply,
         socket
         |> put_flash(:info, "Recording created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
