defmodule DemoWeb.UserSessionController do
  use DemoWeb, :controller

  alias Demo.Accounts
  alias DemoWeb.UserAuth

  def me(conn, _) do
    if conn.assigns[:current_user] do
      conn
      |> render("new.json", user: conn.assigns[:current_user], token: conn.private[:user_token])
    else
      conn
      |> render("new.json")
    end
  end

  def create(conn, %{"user" => user_params}) do
    %{"email" => email, "password" => password} = user_params

    if user = Accounts.get_user_by_email_and_password(email, password) do
      {conn, token} = UserAuth.login_user(conn, user, user_params)

      conn
      |> put_status(:created)
      |> render("new.json", user: user, token: token)
    else
      render(conn, "new.json", error_message: "Invalid e-mail or password")
    end
  end

  def delete(conn, _params) do
    conn
    |> UserAuth.logout_user()
    |> render("delete.json")
  end
end
