defmodule DemoWeb.UserRegistrationView do
  use DemoWeb, :view

  def render("create.json", %{user: user, token: token}) do
    %{
      user: %{email: user.email},
      token: Base.url_encode64(token)
    }
  end

  def render("create.json", %{changeset: changeset}) do
    %{errors: DemoWeb.ErrorHelpers.error_codes(changeset)}
  end
end
