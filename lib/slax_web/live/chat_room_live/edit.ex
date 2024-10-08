defmodule SlaxWeb.ChatRoomLive.Edit do
  use SlaxWeb, :live_view

  alias Slax.Chat

  import SlaxWeb.RoomComponents

  def render(assigns) do
    ~H"""
    <div class="mx-auto w-96 mt-12">
      <.header>
        <%= @page_title %>
        <:actions>
          <.link
            class="font-normal text-xs text-blue-600 hover:text-blue-700"
            navigate={~p"/rooms/#{@room}"}
          >
            Back
          </.link>
        </:actions>
      </.header>

      <.room_form form={@form} />
    </div>
    """
  end

  def mount(%{"id" => id}, _session, socket) do
    room = Chat.get_room!(id)

    if Chat.joined?(room, socket.assigns.current_user) do
      changeset = Chat.change_room(room)

      socket
      |> assign(page_title: "Edit chat room", room: room)
      |> assign_form(changeset)
      |> ok()
    else
      socket
      |> put_flash(:error, "You are not a member of this room")
      |> push_navigate(to: ~p"/")
      |> ok()
    end
  end

  def assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  def handle_event("validate-room", %{"room" => room_params}, socket) do
    changeset =
      socket.assigns.room
      |> Chat.change_room(room_params)
      |> Map.put(:action, :validate)

    socket |> assign_form(changeset) |> noreply()
  end

  def handle_event("save-room", %{"room" => room_params}, socket) do
    case Chat.update_room(socket.assigns.room, room_params) do
      {:ok, room} ->
        socket
        |> put_flash(:info, "Room updated successfully")
        |> push_navigate(to: ~p"/rooms/#{room}")
        |> noreply()

      {:error, %Ecto.Changeset{} = changeset} ->
        socket |> assign_form(changeset) |> noreply()
    end
  end
end
