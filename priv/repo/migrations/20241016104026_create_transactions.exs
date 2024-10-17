defmodule Slax.Repo.Migrations.CreateTransactions do
  use Ecto.Migration

  def change do
    create table(:transactions) do
      add :amount, :integer, null: false
      add :currency, :string, null: false
      add :merchant_reference, :string, null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:transactions, [:user_id])
    create unique_index(:transactions, [:merchant_reference])
  end
end
