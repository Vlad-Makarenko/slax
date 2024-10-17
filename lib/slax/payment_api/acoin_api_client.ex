defmodule Slax.PaymentApi.AcoinApiClient do
  use Tesla

  @api_key "TODO: Hide it to .env"


  plug Tesla.Middleware.BaseUrl, "https://stage.acoin.co.za/api/v1"
  plug Tesla.Middleware.Headers, [{"Authorization", "Bearer #{@api_key}"}]
  plug Tesla.Middleware.JSON

  def check() do
    @api_key |> IO.inspect()
  end

  def get_phone_transaction(transaction_id) do
    get("/phone-redemptions/#{transaction_id}")
  end

  def post_phone_redemption(body) do
    post("/phone-redemptions/", body)
  end
end
