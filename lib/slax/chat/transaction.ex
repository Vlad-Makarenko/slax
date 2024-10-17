defmodule Slax.Chat.Transaction do
  use Ecto.Schema
  import Ecto.Changeset

  alias Slax.Accounts.User

  schema "transactions" do
    field :currency, :string
    field :amount, :integer
    field :merchant_reference, :string
    belongs_to :user, User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(transaction, attrs) do
    transaction
    |> cast(attrs, [:amount, :currency, :merchant_reference])
    |> validate_required([:amount, :currency, :merchant_reference])
    |> unique_constraint(:merchant_reference)
  end
end
