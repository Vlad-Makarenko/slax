defmodule Slax.Repo.Migrations.AddPlanToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :plan, :string, default: "free"
    end
  end
end
