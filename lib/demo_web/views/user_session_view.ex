defmodule DemoWeb.UserSessionView do
  use DemoWeb, :view

  def render("new.json", %{user: user, token: token}) do
    %{
      user: %{email: user.email},
      token: Base.url_encode64(token)
    }
  end

  def render("new.json", %{error_message: error_message}) do
    %{
      error: error_message
    }
  end

  def render("new.json", _) do
    %{}
  end

  def render("delete.json", _) do
    %{message: "Logged out successfully"}
  end
end
