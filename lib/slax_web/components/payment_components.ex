defmodule SlaxWeb.PaymentComponents do
  use SlaxWeb, :html

  alias Slax.Payment.Transaction

  attr :transaction, Transaction, required: true
  attr :timezone, :string, required: true

  def user_transaction(assigns) do
    ~H"""
    <div class="flex flex-col w-full items-center py-3 px-3 border-b border-slate-300">
      <div class="flex w-full items-center">
        <span class="text-sm">
          <span class="italic">Amount:</span> <%= @transaction.amount %> <%= @transaction.currency %>
        </span>
      </div>
      <div class="flex w-full items-center ">
        <span class="text-sm">
          <span class="italic">Reference:</span> <%= @transaction.merchant_reference %>
        </span>
      </div>
      <div class="flex items-center w-full ">
        <span class="text-sm">
          <span class="italic">Date:</span> <%= transaction_timestamp(@transaction, @timezone) %>
        </span>
      </div>
    </div>
    """
  end

  attr :dom_id, :string, required: true

  def upgraded_plan_banner(assigns) do
    ~H"""
    <div
      id={@dom_id}
      class="bg-slate-100 cursor-pointer flex items-center justify-between px-4 py-2 text-sm"
    >
      <span>Want to see more messages in the room? Upgrade your tariff plan!</span>
      <button
        phx-click={show_modal("payment-modal")}
        class="py-2 px-4 border rounded-lg border-slate-200 hover:bg-slate-200 font-semibold"
      >
        Upgrade tariff
      </button>
    </div>
    """
  end

  defp transaction_timestamp(transaction, timezone) do
    transaction.inserted_at
    |> Timex.Timezone.convert(timezone)
    |> Timex.format!("%Y-%m-%d %H:%M", :strftime)
  end
end
