defmodule DemoWeb.UserAuthTest do
  use DemoWeb.ConnCase, async: true

  alias Demo.Accounts
  alias DemoWeb.UserAuth
  import Demo.AccountsFixtures

  setup %{conn: conn} do
    conn =
      conn
      |> Map.replace!(:secret_key_base, DemoWeb.Endpoint.config(:secret_key_base))
      |> init_test_session(%{})

    %{user: user_fixture(), conn: conn}
  end

  describe "login_user/3" do
    test "return a session token and remember_me cookie is configured", %{conn: conn, user: user} do
      assert {conn, token} = UserAuth.login_user(conn, user)
      assert Accounts.get_user_by_session_token(token)
      assert %{value: signed_token} = conn.resp_cookies["user_remember_me"]
    end

    test "writes a cookie if remember_me is configured", %{conn: conn, user: user} do
      {conn, _} = conn |> fetch_cookies() |> UserAuth.login_user(user, %{"remember_me" => "true"})
      assert %{value: signed_token, max_age: max_age} = conn.resp_cookies["user_remember_me"]
      assert max_age == 5_184_000
    end
  end

  describe "logout_user/1" do
    test "erases session and cookies", %{conn: conn, user: user} do
      user_token = Accounts.generate_user_session_token(user)

      conn =
        conn
        |> put_private(:user_token, user_token)
        |> put_req_cookie("user_remember_me", user_token)
        |> fetch_cookies()
        |> UserAuth.logout_user()

      refute conn.cookies["user_remember_me"]
      assert %{max_age: 0} = conn.resp_cookies["user_remember_me"]
      refute Accounts.get_user_by_session_token(user_token)
    end

    @tag :skip
    test "broadcasts to the given live_socket_id", %{conn: conn} do
      live_socket_id = "users_sessions:abcdef-token"
      DemoWeb.Endpoint.subscribe(live_socket_id)

      conn
      |> put_session(:live_socket_id, live_socket_id)
      |> UserAuth.logout_user()

      assert_receive %Phoenix.Socket.Broadcast{
        event: "disconnect",
        topic: "users_sessions:abcdef-token"
      }
    end

    test "works even if user is already logged out", %{conn: conn} do
      conn = conn |> fetch_cookies() |> UserAuth.logout_user()
      refute conn.private[:user_token]
      assert %{max_age: 0} = conn.resp_cookies["user_remember_me"]
    end
  end

  describe "fetch_current_user/2" do
    test "authenticates user from access_token", %{conn: conn, user: user} do
      user_token = Accounts.generate_user_session_token(user)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{Base.url_encode64(user_token)}")
        |> UserAuth.fetch_current_user([])

      assert conn.assigns.current_user.id == user.id
    end

    test "authenticates user from cookies", %{conn: conn, user: user} do
      {logged_in_conn, _} =
        conn |> fetch_cookies() |> UserAuth.login_user(user, %{"remember_me" => "true"})

      user_token = logged_in_conn.cookies["user_remember_me"]
      %{value: signed_token} = logged_in_conn.resp_cookies["user_remember_me"]

      conn =
        conn
        |> put_req_cookie("user_remember_me", signed_token)
        |> UserAuth.fetch_current_user([])

      assert conn.private[:user_token] == user_token
      assert conn.assigns.current_user.id == user.id
    end

    test "does not authenticate if data is missing", %{conn: conn, user: user} do
      _ = Accounts.generate_user_session_token(user)
      conn = UserAuth.fetch_current_user(conn, [])
      refute conn.private[:user_token]
      refute conn.assigns.current_user
    end
  end

  describe "require_authenticated_user/2" do
    test "redirects if user is not authenticated", %{conn: conn} do
      conn = conn |> UserAuth.require_authenticated_user([])
      assert conn.halted
      assert response = json_response(conn, 401)
      assert response["error"] == "You must login to access this page."
    end

    test "does not redirect if user is authenticated", %{conn: conn, user: user} do
      conn = conn |> assign(:current_user, user) |> UserAuth.require_authenticated_user([])
      refute conn.halted
      refute conn.status
    end
  end
end
