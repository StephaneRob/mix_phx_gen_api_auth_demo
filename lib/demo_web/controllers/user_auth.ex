defmodule DemoWeb.UserAuth do
  import Plug.Conn
  import Phoenix.Controller

  alias Demo.Accounts

  # Make the remember me cookie valid for 60 days.
  # If you want bump or reduce this value, also change
  # the token expiry itself in UserToken.
  @max_age 60 * 60 * 24 * 60
  @remember_me_cookie "user_remember_me"
  @remember_me_options [sign: true]

  @realm "Bearer"

  @doc """
  Logs the user in.
  """
  def login_user(conn, user, params \\ %{}) do
    token = Accounts.generate_user_session_token(user)

    conn =
      conn
      |> write_remember_me_cookie(token, params)

    {conn, token}
  end

  defp write_remember_me_cookie(conn, token, %{"remember_me" => "true"}) do
    remember_me_options_with_max_age = Keyword.put(@remember_me_options, :max_age, @max_age)
    put_resp_cookie(conn, @remember_me_cookie, token, remember_me_options_with_max_age)
  end

  defp write_remember_me_cookie(conn, token, _params) do
    put_resp_cookie(conn, @remember_me_cookie, token, @remember_me_options)
  end

  @doc """
  Logs the user out.
  """
  def logout_user(conn) do
    user_token = conn.private[:user_token]
    user_token && Accounts.delete_session_token(user_token)

    conn
    |> put_private(:user_token, nil)
    |> delete_resp_cookie(@remember_me_cookie)
  end

  @doc """
  Authenticates the user by looking into the header
  and remember me token.
  """
  def fetch_current_user(conn, _opts) do
    {user_token, conn} = ensure_user_token(conn)
    user = user_token && Accounts.get_user_by_session_token(user_token)

    conn
    |> assign(:current_user, user)
    |> put_private(:user_token, user_token)
  end

  defp ensure_user_token(conn) do
    if user_token = get_bearer(get_req_header(conn, "authorization")) do
      {Base.url_decode64!(user_token), conn}
    else
      conn = fetch_cookies(conn, signed: [@remember_me_cookie])

      if user_token = conn.cookies[@remember_me_cookie] do
        {user_token, conn}
      else
        {nil, conn}
      end
    end
  end

  defp get_bearer(["#{@realm} " <> token]) do
    token
  end

  defp get_bearer(_) do
    nil
  end

  @doc """
  Used for routes that require the user to not be authenticated.
  """
  def redirect_if_user_is_authenticated(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
      |> redirect(to: signed_in_path(conn))
      |> halt()
    else
      conn
    end
  end

  @doc """
  Used for routes that require the user to be authenticated.

  If you want to enforce the user e-mail is confirmed before
  they use the application at all, here would be a good place.
  """
  def require_authenticated_user(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
    else
      conn
      |> put_status(:unauthorized)
      |> put_view(DemoWeb.UserAuthView)
      |> render("unauthenticated.json",
        error: "You must login to access this page."
      )
      |> halt()
    end
  end

  defp signed_in_path(_conn), do: "/"

  def require_guest(conn, _) do
    if conn.assigns[:current_user] do
      conn
      |> put_status(:forbidden)
      |> put_view(DemoWeb.UserAuthView)
      |> render("authenticated.json", error: "You're already logged in")
      |> halt()
    else
      conn
    end
  end
end
