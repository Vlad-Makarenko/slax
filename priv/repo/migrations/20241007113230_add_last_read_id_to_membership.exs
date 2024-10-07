defmodule Slax.Repo.Migrations.AddLastReadIdToMembership do
  use Ecto.Migration

  def change do
    alter table(:room_memberships) do
      add :last_read_id, :integer
    end
  end
end
