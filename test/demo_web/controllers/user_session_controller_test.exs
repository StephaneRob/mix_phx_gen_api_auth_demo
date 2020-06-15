defmodule DemoWeb.UserSessionControllerTest do
  use DemoWeb.ConnCase, async: true

  import Demo.AccountsFixtures

  setup do
    %{user: user_fixture()}
  end

  describe "GET /users/me" do
    test "resend the token back if refresh cookie", %{conn: conn, user: user} do
      conn = conn |> login_user(user) |> get(Routes.user_session_path(conn, :me))
      assert response = json_response(conn, 200)
      assert response["user"]["email"]
      assert response["token"]
    end

    test "empty response if no user", %{conn: conn} do
      conn = get(conn, Routes.user_session_path(conn, :me))
      assert response = json_response(conn, 200)
      assert response == %{}
    end
  end

  describe "POST /users/login" do
    test "logs the user in", %{conn: conn, user: user} do
      conn =
        post(conn, Routes.user_session_path(conn, :create), %{
          "user" => %{"email" => user.email, "password" => valid_user_password()}
        })

      assert response = json_response(conn, 201)
      assert response["user"]["email"]
      assert response["token"]
      assert conn.resp_cookies["user_remember_me"]
      refute conn.resp_cookies["user_remember_me"][:max_age]
    end

    test "logs the user in with remember me", %{conn: conn, user: user} do
      conn =
        post(conn, Routes.user_session_path(conn, :create), %{
          "user" => %{
            "email" => user.email,
            "password" => valid_user_password(),
            "remember_me" => "true"
          }
        })

      assert conn.resp_cookies["user_remember_me"]
      assert conn.resp_cookies["user_remember_me"][:max_age] == 5_184_000
    end

    test "emits error message with invalid credentials", %{conn: conn, user: user} do
      conn =
        post(conn, Routes.user_session_path(conn, :create), %{
          "user" => %{"email" => user.email, "password" => "invalid_password"}
        })

      response = json_response(conn, 200)
      assert response["error"] == "Invalid e-mail or password"
    end
  end

  describe "DELETE /users/logout" do
    test "logs the user out", %{conn: conn, user: user} do
      conn = conn |> login_user(user) |> delete(Routes.user_session_path(conn, :delete))
      assert response = json_response(conn, 200)
      assert response["message"] =~ "Logged out successfully"
    end

    test "succeeds even if the user is not logged in", %{conn: conn} do
      conn = delete(conn, Routes.user_session_path(conn, :delete))
      assert response = json_response(conn, 200)
      assert response["message"] =~ "Logged out successfully"
    end
  end
end
