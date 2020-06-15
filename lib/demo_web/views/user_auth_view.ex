defmodule DemoWeb.UserAuthView do
  use DemoWeb, :view

  def render("unauthenticated.json", %{error: error}) do
    %{error: error}
  end

  def render("authenticated.json", %{error: error}) do
    %{error: error}
  end

  def render("invalid_reset_password_token.json", %{error: error}) do
    %{error: error}
  end
end
