defmodule Slax.Payment.PaymentService do
  alias Slax.Repo
  alias Slax.Payment.Transaction
  alias Slax.Payment.AcoinApiClient
  alias Slax.Accounts.User

  @pubsub Slax.PubSub

  def get_phone_transaction_info(transaction_id) when is_binary(transaction_id) do
    case AcoinApiClient.get_phone_transaction(transaction_id) do
      {:ok, %Tesla.Env{status: 200, body: %{"success" => true} = body}} ->
        {:ok, body}

      {:ok, %Tesla.Env{body: body}} ->
        {:error, body}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def tariff_plan(info) when is_binary(info) do
    case info do
      "basic" -> 20
      "advanced" -> 100
    end
  end

  def tariff_plan(info) when is_integer(info) do
    case info do
      20 -> "basic"
      100 -> "advanced"
    end
  end

  def create_phone_redemption(%User{} = current_user, phone_number, subscribe_level)
      when is_binary(phone_number) do
    timestamp = :os.system_time(:millisecond)

    body = %{
      phone_number: phone_number,
      amount: tariff_plan(subscribe_level),
      merchant_reference: "#{current_user.username}-#{timestamp}",
      notify_url: Application.get_env(:slax, :secrets)[:notify_url],
      success_url: Application.get_env(:slax, :secrets)[:success_url],
      cancel_url: Application.get_env(:slax, :secrets)[:cancel_url],
      error_url: Application.get_env(:slax, :secrets)[:error_url]
    }

    case AcoinApiClient.post_phone_redemption(body) do
      {:ok, %Tesla.Env{status: 201, body: %{"success" => true} = body}} ->
        {:ok, body}

      {:ok, %Tesla.Env{body: body}} ->
        {:error, body}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def create_transaction(user, attrs) do
    %Transaction{user: user}
    |> Transaction.changeset(attrs)
    |> Repo.insert()
  end

  def get_transaction_by_merchant_reference(merchant_reference) do
    Repo.get_by(Transaction, merchant_reference: merchant_reference)
  end

  def subscribe_to_tariff_upgrade(user) do
    Phoenix.PubSub.subscribe(@pubsub, "payment_status:#{user.id}")
  end
end
