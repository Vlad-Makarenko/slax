defmodule Slax.Chat do
  alias Slax.Accounts.User
  alias Slax.Chat.{Room, Message}
  alias Slax.Repo

  import Ecto.Query

  def get_first_room! do
    Repo.one!(from room in Room, limit: 1, order_by: [asc: :name])
  end

  def get_room!(id) do
    Room |> Repo.get!(id)
  end

  def list_rooms do
    Repo.all(from room in Room, order_by: [asc: :name])
  end

  def create_room(attrs) do
    %Room{}
    |> Room.changeset(attrs)
    |> Repo.insert()
  end

  def change_room(room, attrs \\ %{}) do
    Room.changeset(room, attrs)
  end

  def update_room(%Room{} = room, attrs) do
    room
    |> Room.changeset(attrs)
    |> Repo.update()
  end

  def list_messages_in_room(%Room{id: room_id}) do
    Message
    |> where([m], m.room_id == ^room_id)
    |> preload(:user)
    |> order_by([m], asc: :inserted_at, asc: :id)
    |> Repo.all()
  end

  def change_message(message, attrs \\ %{}) do
    Message.changeset(message, attrs)
  end

  def create_message(room, attrs, user) do
    %Message{room: room, user: user}
    |> Message.changeset(attrs)
    |> Repo.insert()
  end

  def delete_message_by_id(id, %User{id: user_id}) do
    message = %Message{user_id: ^user_id} = Repo.get!(Message, id)

    Repo.delete(message)
  end
end
