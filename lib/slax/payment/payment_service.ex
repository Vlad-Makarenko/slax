defmodule Slax.Payment.PaymentService do
  alias Slax.Repo
  alias Slax.Payment.Transaction
  alias Slax.Payment.AcoinApiClient
  alias Slax.Accounts.User

  @pubsub Slax.PubSub

  # Maybe hide it somewhere?
  @tariff_plans [
    %{
      level: "basic",
      price: 20,
      info: "You can read up to 50 messages in rooms",
      disabled: false
    },
    %{
      level: "advanced",
      price: 100,
      info: "You can read unlimited number of messages",
      disabled: false
    }
  ]

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

  def get_tariff_plans(%User{} = user) do
    case user.plan do
      "free" ->
        @tariff_plans

      "basic" ->
        Enum.map(@tariff_plans, fn plan ->
          case plan.level do
            "basic" ->
              updated_info = "#{plan.info} (your current plan)"
              Map.put(plan, :disabled, true) |> Map.put(:price, 0) |> Map.put(:info, updated_info)

            "advanced" ->
              updated_price = plan.price - 20
              updated_info = "#{plan.info} (discount applied)"
              Map.put(plan, :price, updated_price) |> Map.put(:info, updated_info)

            _ ->
              plan
          end
        end)

      "advanced" ->
        [
          %{
            level: "advanced",
            price: 0,
            info: "You already have the highest plan!",
            disabled: false
          }
        ]

      _ ->
        @tariff_plans
    end
  end

  def get_tariff_plans(_), do: @tariff_plans

  def get_plan_price(%User{} = user, chosen_plan) when is_binary(chosen_plan) do
    with %{} = plan <- Enum.find(@tariff_plans, fn plan -> plan.level == chosen_plan end) do
      case {user.plan, chosen_plan} do
        {"basic", "advanced"} ->
          {:ok, plan.price - Enum.find(@tariff_plans, fn p -> p.level == "basic" end).price}

        {"basic", "basic"} ->
          {:error, "You already have the basic plan. Choose a higher plan."}

        {"advanced", "advanced"} ->
          {:error, "You already have the highest plan."}

        _ ->
          {:ok, plan.price}
      end
    else
      nil -> {:error, "Invalid plan selected."}
    end
  end

  def tariff_by_code(code) do
    case code do
      "B" -> "basic"
      "A" -> "advanced"
    end
  end

  # TODO: Maybe fix nested
  def create_phone_redemption(%User{} = current_user, phone_number, subscribe_level)
      when is_binary(phone_number) do
    case get_plan_price(current_user, subscribe_level) do
      {:ok, price} ->
        timestamp = :os.system_time(:millisecond)
        subscribe_code = subscribe_level |> String.upcase() |> String.first()

        body = %{
          phone_number: phone_number,
          amount: price,
          merchant_reference: "#{current_user.username}-#{subscribe_code}-#{timestamp}",
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
