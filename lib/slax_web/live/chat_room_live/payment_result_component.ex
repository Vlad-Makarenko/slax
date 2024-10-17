defmodule SlaxWeb.ChatRoomLive.PaymentResultComponent do
  use SlaxWeb, :live_component

  alias Slax.PaymentService

  def render(assigns) do
    ~H"""
    <div id="payment-result" class="flex justify-center w-full">
      <%= if @success do %>
        <div class="flex flex-col gap-3 justify-center items-center w-full">
          <.icon name="hero-check-circle" class="h-24 w-24 text-green-500" />
          <h1 class="text-lg font-bold text-gray-800">Payment successful</h1>
          <span class="text-lg text-gray-800">
            Welcome to <span class="text-lg font-bold text-gray-800"><%= @current_user.plan %></span>
            tariff plan!
          </span>
          <span class="text-lg text-gray-800">
            Now you can see
            <span class="text-lg font-bold text-gray-800">
              <%= if @current_user.plan == "advanced",
                do: "an unlimited number of",
                else: "up to 50" %>
            </span>
            messages in rooms.
          </span>
          <button
            class="w-1/3 border rounded-lg border-slate-200 py-2 hover:bg-slate-200"
            phx-click={JS.navigate(~p"/")}
          >
            Ok
          </button>
        </div>
      <% else %>
        <div class="flex flex-col gap-3 justify-center w-full">
          <.icon name="hero-x-circle" class="h-24 w-24 text-red-500" />
          <h1 class="text-lg font-bold text-gray-800">Payment failed!</h1>
          <span class="text-lg text-gray-800">
            It seems something went wrong... please try again later.
          </span>

          <button
            class="w-1/3 border rounded-lg border-slate-200 py-2 hover:bg-slate-200"
            phx-click={JS.navigate(~p"/")}
          >
            Ok
          </button>
        </div>
      <% end %>
    </div>
    """
  end

  def update(assigns, socket) do
    case assigns.payment_result do
      %{"merchant_reference" => merchant_reference, "type" => type} ->
        if PaymentService.get_transaction_by_merchant_reference(merchant_reference) do
          success = type == "success"
          socket |> assign(assigns) |> assign(success: success) |> ok()
        else
          socket |> push_patch(to: ~p"/") |> ok()
        end

      nil ->
        socket |> assign(assigns) |> assign(success: false) |> ok()
    end
  end
end
