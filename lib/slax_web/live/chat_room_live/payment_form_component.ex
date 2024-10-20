defmodule SlaxWeb.ChatRoomLive.PaymentFormComponent do
  alias Slax.Payment.PaymentService
  use SlaxWeb, :live_component

  def render(assigns) do
    ~H"""
    <div id="payment-form" phx-hook="Redirect">
      <form
        phx-submit="submit"
        phx-change="validate"
        phx-target={@myself}
        class="flex flex-col w-full gap-3 py-3"
      >
        <span class="w-ful rounded-lg">
          Tariff plan:
        </span>

        <div class="flex flex-col space-y-2">
          <%= for item <- @plans_list do %>
            <label class="w-full">
              <input
                type="radio"
                name="option"
                value={item.level}
                checked={@option == item.level}
                disabled={item.disabled}
                phx-change="validate"
                class="hidden peer"
              />
              <p class="block w-full bg-slate-100 py-2 px-2 rounded-lg cursor-pointer peer-checked:bg-slate-300">
                R<%= item.price %><span class="font-bold"> <%= String.capitalize(item.level) %></span> - <%= item.info %>
              </p>
            </label>
          <% end %>
        </div>

        <label class="w-full">
          <span class="w-ful py-2 rounded-lg">
            Phone number
          </span>
          <.input
            type="text"
            name="phone_number"
            placeholder="e.g. +27 12 345 6789"
            value={@phone_number}
            required
            phx-debounce="1000"
          />
        </label>
        <span class="text-red-500 w-full">
          <%= @message %>
        </span>
        <button type="submit" class="w-full bg-green-200 hover:bg-green-300 rounded-lg py-2">
          Submit
        </button>
      </form>
    </div>
    """
  end

  def update(assigns, socket) do
    plans = PaymentService.get_tariff_plans(assigns.current_user)

    socket
    |> assign(:plans_list, plans)
    |> assign(:phone_number, "")
    |> assign(:option, "advanced")
    |> assign(:message, "")
    |> assign(assigns)
    |> ok()
  end

  def handle_event("validate", %{"phone_number" => phone_number, "option" => _option}, socket) do
    case validate_phone_number(phone_number) do
      :ok ->
        {:noreply, assign(socket, message: "", phone_number: phone_number)}

      {:error, reason} ->
        {:noreply, assign(socket, message: reason, phone_number: phone_number)}
    end
  end

  def handle_event("validate", %{"option" => option}, socket) do
    case valid_option(option, socket.assigns.plans_list) do
      :ok ->
        {:noreply, assign(socket, message: "", option: option)}

      {:error, reason} ->
        {:noreply, assign(socket, message: reason, option: option)}
    end
  end

  def handle_event("submit", %{"phone_number" => phone_number, "option" => option}, socket) do
    with :ok <- validate_phone_number(phone_number),
         :ok <- valid_option(option, socket.assigns.plans_list),
         {:ok, body} <-
           PaymentService.create_phone_redemption(
             socket.assigns.current_user,
             phone_number,
             option
           ) do
      body |> IO.inspect()
      socket |> redirect(external: body["redirect_url"]) |> noreply()
    else
      {:error, %{"message" => message}} ->
        socket
        |> put_flash(:error, "Payment error! #{message}")
        |> assign(:message, message)
        |> noreply()

      {:error, reason} ->
        {:noreply, assign(socket, message: reason)}
    end
  end

  defp valid_option(option, plans_list) do
    with %{} = plan <- Enum.find(plans_list, fn plan -> plan.level == option end),
         false <- plan.disabled do
      :ok
    else
      nil ->
        {:error, "Invalid plan selected."}

      true ->
        {:error, "The selected plan is not available for upgrade."}
    end
  end

  defp validate_phone_number(phone_number) do
    if String.match?(phone_number, ~r/^\+27\d{9}$/) do
      :ok
    else
      {:error, "Please enter a valid phone number."}
    end
  end
end
