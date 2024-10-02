defmodule Slax.Chat do
  alias Slax.Chat.Room
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
end
