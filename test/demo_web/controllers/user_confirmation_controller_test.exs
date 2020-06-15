defmodule DemoWeb.UserConfirmationControllerTest do
  use DemoWeb.ConnCase, async: true

  alias Demo.Accounts
  alias Demo.Repo
  import Demo.AccountsFixtures

  setup do
    %{user: user_fixture()}
  end

  describe "POST /users/confirm" do
    @tag :capture_log
    test "sends a new confirmation token", %{conn: conn, user: user} do
      conn =
        post(conn, Routes.user_confirmation_path(conn, :create), %{
          "user" => %{"email" => user.email}
        })

      assert response = json_response(conn, 200)
      assert response["message"] =~ "If your e-mail is in our system"
      assert Repo.get_by!(Accounts.UserToken, user_id: user.id).context == "confirm"
    end

    test "does not send confirmation token if account is confirmed", %{conn: conn, user: user} do
      Repo.update!(Accounts.User.confirm_changeset(user))

      conn =
        post(conn, Routes.user_confirmation_path(conn, :create), %{
          "user" => %{"email" => user.email}
        })

      assert response = json_response(conn, 200)
      assert response["message"] =~ "If your e-mail is in our system"
      refute Repo.get_by(Accounts.UserToken, user_id: user.id)
    end

    test "does not send confirmation token if email is invalid", %{conn: conn} do
      conn =
        post(conn, Routes.user_confirmation_path(conn, :create), %{
          "user" => %{"email" => "unknown@example.com"}
        })

      assert response = json_response(conn, 200)
      assert response["message"] =~ "If your e-mail is in our system"
      assert Repo.all(Accounts.UserToken) == []
    end
  end

  describe "GET /users/confirm/:token" do
    test "confirms the given token once", %{conn: conn, user: user} do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_confirmation_instructions(user, url)
        end)

      conn = get(conn, Routes.user_confirmation_path(conn, :confirm, token))
      assert response = json_response(conn, 200)
      assert response["message"] =~ "Account confirmed successfully"
      assert Accounts.get_user!(user.id).confirmed_at
      assert Repo.all(Accounts.UserToken) == []

      conn = get(conn, Routes.user_confirmation_path(conn, :confirm, token))
      assert response = json_response(conn, 200)
      assert response["error"] =~ "Confirmation link is invalid or it has expired"
    end

    test "does not confirm email with invalid token", %{conn: conn, user: user} do
      conn = get(conn, Routes.user_confirmation_path(conn, :confirm, "oops"))
      assert response = json_response(conn, 200)
      assert response["error"] =~ "Confirmation link is invalid or it has expired"
      refute Accounts.get_user!(user.id).confirmed_at
    end
  end
end
