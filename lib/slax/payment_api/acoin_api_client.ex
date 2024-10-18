defmodule Slax.PaymentApi.AcoinApiClient do
  use Tesla

  def client() do
    api_key = Application.get_env(:slax, :secrets)[:acoin_api_key]

    middleware = [
      {Tesla.Middleware.BaseUrl, "https://stage.acoin.co.za/api/v1"},
      Tesla.Middleware.JSON,
      {Tesla.Middleware.Headers, [{"Authorization", "Bearer #{api_key}"}]}
    ]

    Tesla.client(middleware)
  end

  def get_phone_transaction(transaction_id) do
    client() |> Tesla.get("/phone-redemptions/#{transaction_id}")
  end

  def post_phone_redemption(body) do
    client() |> Tesla.post("/phone-redemptions/", body)
  end
end
