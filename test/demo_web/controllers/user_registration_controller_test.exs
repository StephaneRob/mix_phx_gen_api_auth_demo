defmodule DemoWeb.UserRegistrationControllerTest do
  use DemoWeb.ConnCase, async: true

  import Demo.AccountsFixtures

  describe "POST /users/register" do
    @tag :capture_log
    test "creates account and logs the user in", %{conn: conn} do
      email = unique_user_email()

      conn =
        post(conn, Routes.user_registration_path(conn, :create), %{
          "user" => %{"email" => email, "password" => valid_user_password()}
        })

      assert response = json_response(conn, 201)
      assert response["token"]
    end

    test "render errors for invalid data", %{conn: conn} do
      conn =
        post(conn, Routes.user_registration_path(conn, :create), %{
          "user" => %{"email" => "with spaces", "password" => "too short"}
        })

      assert response = json_response(conn, 422)
      assert response["errors"]["email"] == ["must have the @ sign and no spaces"]
      assert response["errors"]["password"] == ["should be at least 12 character(s)"]
    end
  end
end
