defmodule DemoWeb.UserConfirmationController do
  use DemoWeb, :controller

  alias Demo.Accounts
  alias DemoWeb.FrontRouter

  def create(conn, %{"user" => %{"email" => email}}) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_user_confirmation_instructions(
        user,
        &FrontRouter.user_confirmation_url(&1)
      )
    end

    # Regardless of the outcome, show an impartial success/error message.
    conn
    |> render("create.json")
  end

  # Do not login the user after confirmation to avoid a
  # leaked token giving the user access to the account.
  def confirm(conn, %{"token" => token}) do
    case Accounts.confirm_user(token) do
      {:ok, _} ->
        conn
        |> render("confirm.json")

      :error ->
        conn
        |> render("confirm.json", error: "Confirmation link is invalid or it has expired.")
    end
  end
end
