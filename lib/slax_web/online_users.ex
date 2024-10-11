defmodule SlaxWeb.OnlineUsers do
  alias SlaxWeb.Presence

  @topic "online_users"

  def list() do
    @topic
    |> Presence.list()
    |> Enum.into(%{}, fn {id, %{metas: metas}} ->
      {String.to_integer(id), %{count: length(metas), typing: check_typing(metas)}}
    end)
  end

  defp check_typing(metas) do
    Enum.any?(metas, fn meta -> Map.get(meta, :typing, false) end)
  end

  def track(pid, user) do
    {:ok, _} = Presence.track(pid, @topic, user.id, %{typing: false})
    :ok
  end

  def update_typing(user_id, typing) do
    Presence.update(self(), @topic, user_id, fn meta ->
      Map.put(meta, :typing, typing)
    end)
  end

  def online?(online_users, user_id) do
    Map.get(online_users, user_id, %{})
    |> Map.get(:count, 0) > 0
  end

  def typing?(online_users, user_id) do
    Map.get(online_users, user_id, %{})
    |> Map.get(:typing, false)
  end

  def subscribe() do
    Phoenix.PubSub.subscribe(Slax.PubSub, @topic)
  end

  def update(online_users, %{joins: joins, leaves: leaves}) do
    online_users
    |> typing_updates(joins)
    |> process_updates(joins, &Kernel.+/2)
    |> process_updates(leaves, &Kernel.-/2)
  end

  defp process_updates(online_users, updates, operation) do
    Enum.reduce(updates, online_users, fn {id, %{metas: metas}}, acc ->
      Map.update(acc, String.to_integer(id), %{count: length(metas), typing: false}, fn meta ->
        %{meta | count: operation.(meta.count, length(metas))}
      end)
    end)
  end

  defp typing_updates(online_users, updates) do
    Enum.reduce(updates, online_users, fn {id, %{metas: metas}}, acc ->
      Map.update(acc, String.to_integer(id), %{count: length(metas), typing: false}, fn meta ->
        %{meta | typing: check_typing(metas)}
      end)
    end)
  end
end
