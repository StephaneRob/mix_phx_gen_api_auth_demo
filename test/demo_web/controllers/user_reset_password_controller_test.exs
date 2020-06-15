defmodule DemoWeb.UserResetPasswordControllerTest do
  use DemoWeb.ConnCase, async: true

  alias Demo.Accounts
  alias Demo.Repo
  import Demo.AccountsFixtures

  setup do
    %{user: user_fixture()}
  end

  describe "POST /users/reset_password" do
    @tag :capture_log
    test "sends a new reset password token", %{conn: conn, user: user} do
      conn =
        post(conn, Routes.user_reset_password_path(conn, :create), %{
          "user" => %{"email" => user.email}
        })

      assert response = json_response(conn, 200)
      assert response["message"] =~ "If your e-mail is in our system"
      assert Repo.get_by!(Accounts.UserToken, user_id: user.id).context == "reset_password"
    end

    test "does not send reset password token if email is invalid", %{conn: conn} do
      conn =
        post(conn, Routes.user_reset_password_path(conn, :create), %{
          "user" => %{"email" => "unknown@example.com"}
        })

      assert response = json_response(conn, 200)
      assert response["message"] =~ "If your e-mail is in our system"
      assert Repo.all(Accounts.UserToken) == []
    end
  end

  describe "PUT /users/reset_password/:token" do
    setup %{user: user} do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_reset_password_instructions(user, url)
        end)

      %{token: token}
    end

    test "resets password once", %{conn: conn, user: user, token: token} do
      conn =
        put(conn, Routes.user_reset_password_path(conn, :update, token), %{
          "user" => %{
            "password" => "new valid password",
            "password_confirmation" => "new valid password"
          }
        })

      assert response = json_response(conn, 200)
      assert response["message"] =~ "Password reset successfully"
      assert Accounts.get_user_by_email_and_password(user.email, "new valid password")
    end

    test "does not reset password on invalid data", %{conn: conn, token: token} do
      conn =
        put(conn, Routes.user_reset_password_path(conn, :update, token), %{
          "user" => %{
            "password" => "too short",
            "password_confirmation" => "does not match"
          }
        })

      assert response = json_response(conn, 422)
      assert response["errors"]["password"] == ["should be at least 12 character(s)"]
      assert response["errors"]["password_confirmation"] == ["does not match password"]
    end

    test "does not reset password with invalid token", %{conn: conn} do
      conn = put(conn, Routes.user_reset_password_path(conn, :update, "oops"))
      assert response = json_response(conn, 401)
      assert response["error"] =~ "Reset password link is invalid or it has expired"
    end
  end
end
