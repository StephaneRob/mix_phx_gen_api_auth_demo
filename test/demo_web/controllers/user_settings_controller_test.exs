defmodule DemoWeb.UserSettingsControllerTest do
  use DemoWeb.ConnCase, async: true

  alias Demo.Accounts
  import Demo.AccountsFixtures

  setup :register_and_login_user

  describe "PUT /users/settings/update_password" do
    test "updates the user password and resets tokens", %{conn: conn, user: user} do
      new_password_conn =
        put(conn, Routes.user_settings_path(conn, :update_password), %{
          "current_password" => valid_user_password(),
          "user" => %{
            "password" => "new valid password",
            "password_confirmation" => "new valid password"
          }
        })

      assert response = json_response(new_password_conn, 200)
      assert response["user"]
      assert response["token"]
      assert Accounts.get_user_by_email_and_password(user.email, "new valid password")
    end

    test "does not update password on invalid data", %{conn: conn} do
      old_password_conn =
        put(conn, Routes.user_settings_path(conn, :update_password), %{
          "current_password" => "invalid",
          "user" => %{
            "password" => "too short",
            "password_confirmation" => "does not match"
          }
        })

      assert response = json_response(old_password_conn, 422)
      assert response["errors"]["password"] == ["should be at least 12 character(s)"]
      assert response["errors"]["password_confirmation"] == ["does not match password"]
      assert response["errors"]["current_password"] == ["is not valid"]

      # FIXME
      # assert get_session(old_password_conn, :user_token) == get_session(conn, :user_token)
    end
  end

  describe "PUT /users/settings/update_email" do
    @tag :capture_log
    test "updates the user email", %{conn: conn, user: user} do
      conn =
        put(conn, Routes.user_settings_path(conn, :update_email), %{
          "current_password" => valid_user_password(),
          "user" => %{"email" => unique_user_email()}
        })

      assert response = json_response(conn, 200)
      assert response["message"] =~ "A link to confirm your e-mail"
      assert Accounts.get_user_by_email(user.email)
    end

    test "does not update email on invalid data", %{conn: conn} do
      conn =
        put(conn, Routes.user_settings_path(conn, :update_email), %{
          "current_password" => "invalid",
          "user" => %{"email" => "with spaces"}
        })

      assert response = json_response(conn, 422)
      assert response["errors"]["email"] == ["must have the @ sign and no spaces"]
      assert response["errors"]["current_password"] == ["is not valid"]
    end
  end

  describe "GET /users/settings/confirm_email/:token" do
    setup %{user: user} do
      email = unique_user_email()

      token =
        extract_user_token(fn url ->
          Accounts.deliver_update_email_instructions(%{user | email: email}, user.email, url)
        end)

      %{token: token, email: email}
    end

    test "updates the user email once", %{conn: conn, user: user, token: token, email: email} do
      conn = get(conn, Routes.user_settings_path(conn, :confirm_email, token))
      assert response = json_response(conn, 200)
      assert response["message"] =~ "E-mail changed successfully"
      refute Accounts.get_user_by_email(user.email)
      assert Accounts.get_user_by_email(email)

      conn = get(conn, Routes.user_settings_path(conn, :confirm_email, token))
      assert response = json_response(conn, 200)
      assert response["error"] =~ "Email change link is invalid or it has expired"
    end

    test "does not update email with invalid token", %{conn: conn} do
      conn = get(conn, Routes.user_settings_path(conn, :confirm_email, "oops"))
      assert response = json_response(conn, 200)
      assert response["error"] =~ "Email change link is invalid or it has expired"
    end

    test "redirects if user is not logged in", %{token: token} do
      conn = build_conn()
      conn = get(conn, Routes.user_settings_path(conn, :confirm_email, token))
      assert response = json_response(conn, 401)
      assert response["error"] == "You must login to access this page."
    end
  end
end
