defmodule DemoWeb.UserSettingsController do
  use DemoWeb, :controller

  alias Demo.Accounts
  alias DemoWeb.UserAuth
  alias DemoWeb.FrontRouter

  plug :assign_email_and_password_changesets

  def update_email(conn, %{"current_password" => password, "user" => user_params}) do
    user = conn.assigns.current_user

    case Accounts.apply_user_email(user, password, user_params) do
      {:ok, applied_user} ->
        Accounts.deliver_update_email_instructions(
          applied_user,
          user.email,
          &FrontRouter.user_settings_url(&1)
        )

        conn
        |> render("update_email.json", user: applied_user)

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render("update_email.json", email_changeset: changeset)
    end
  end

  def confirm_email(conn, %{"token" => token}) do
    case Accounts.update_user_email(conn.assigns.current_user, token) do
      :ok ->
        conn
        |> render("confirm_email.json")

      :error ->
        conn
        |> render("confirm_email.json", error: "Email change link is invalid or it has expired.")
    end
  end

  def update_password(conn, %{"current_password" => password, "user" => user_params}) do
    user = conn.assigns.current_user

    case Accounts.update_user_password(user, password, user_params) do
      {:ok, user} ->
        {conn, token} =
          conn
          |> UserAuth.login_user(user)

        conn
        |> render("update_password.json", user: user, token: token)

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render("update_password.json", password_changeset: changeset)
    end
  end

  defp assign_email_and_password_changesets(conn, _opts) do
    user = conn.assigns.current_user

    conn
    |> assign(:email_changeset, Accounts.change_user_email(user))
    |> assign(:password_changeset, Accounts.change_user_password(user))
  end
end
