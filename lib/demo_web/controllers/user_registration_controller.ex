defmodule DemoWeb.UserRegistrationController do
  use DemoWeb, :controller

  alias Demo.Accounts
  alias DemoWeb.UserAuth

  def create(conn, %{"user" => user_params}) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        {:ok, _} =
          Accounts.deliver_user_confirmation_instructions(
            user,
            &Routes.user_confirmation_url(conn, :confirm, &1)
          )

        {conn, token} = UserAuth.login_user(conn, user, user_params)

        conn
        |> put_status(:created)
        |> render("create.json", user: user, token: token)

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render("create.json", changeset: changeset)
    end
  end
end
