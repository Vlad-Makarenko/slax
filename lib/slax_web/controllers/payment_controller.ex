defmodule SlaxWeb.PaymentController do
  use SlaxWeb, :controller

  alias Slax.Accounts
  alias Slax.Payment.PaymentService

  @pubsub Slax.PubSub

  def payment_callback(
        %Plug.Conn{
          body_params: %{
            "merchant_reference" => merchant_reference,
            "transaction_id" => transaction_id
          }
        } = conn,
        _
      ) do
    # TODO: verify hash somehow

    if PaymentService.get_transaction_by_merchant_reference(merchant_reference) do
      conn
      |> put_status(:bad_request)
      |> json(%{message: "Something went wrong"})
      |> halt()

      # TODO: ASK if it`s ok to do like that? or better use 'with'
    else
      case PaymentService.get_phone_transaction_info(transaction_id) do
        {:ok, body} ->
          IO.inspect(body)
          [username | [code | _]] = body["merchant_reference"] |> String.split("-")
          # TODO: Ask or find info if it is ok to do like that or need to pattern match this
          user = Accounts.get_user_by_username(username)
          PaymentService.create_transaction(user, body)

          {:ok, updated_user} =
            Accounts.update_user_tariff_plan(user, PaymentService.tariff_by_code(code))

          Phoenix.PubSub.broadcast!(@pubsub, "payment_status:#{updated_user.id}", %{
            plan_upgraded: updated_user
          })

          conn
          |> put_status(:ok)
          |> json(%{message: "Transaction processed successfully"})
          |> halt()

        {:error, _} ->
          conn
          |> put_status(:bad_request)
          |> json(%{message: "Something went wrong"})
          |> halt()
      end
    end
  end

  def payment_callback(conn, _) do
    conn
    |> put_status(:bad_request)
    |> json(%{message: "Something went wrong"})
    |> halt()
  end
end
