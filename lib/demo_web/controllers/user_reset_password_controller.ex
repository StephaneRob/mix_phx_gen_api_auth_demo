defmodule DemoWeb.UserResetPasswordController do
  use DemoWeb, :controller

  alias Demo.Accounts
  alias DemoWeb.FrontRouter

  plug :get_user_by_reset_password_token when action in [:edit, :update]

  def create(conn, %{"user" => %{"email" => email}}) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_user_reset_password_instructions(
        user,
        &FrontRouter.user_reset_password_url(&1)
      )
    end

    # Regardless of the outcome, show an impartial success/error message.
    conn
    |> render("create.json")
  end

  # Do not login the user after reset password to avoid a
  # leaked token giving the user access to the account.
  def update(conn, %{"user" => user_params}) do
    case Accounts.reset_user_password(conn.assigns.user, user_params) do
      {:ok, _} ->
        conn
        |> render("update.json")

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render("update.json", changeset: changeset)
    end
  end

  defp get_user_by_reset_password_token(conn, _opts) do
    %{"token" => token} = conn.params

    if user = Accounts.get_user_by_reset_password_token(token) do
      conn |> assign(:user, user) |> assign(:token, token)
    else
      conn
      |> put_status(:unauthorized)
      |> put_view(DemoWeb.UserAuthView)
      |> render("invalid_reset_password_token.json",
        error: "Reset password link is invalid or it has expired."
      )
      |> halt()
    end
  end
end
