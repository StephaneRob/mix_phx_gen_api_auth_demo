defmodule DemoWeb.UserSettingsView do
  use DemoWeb, :view

  def render("update_email.json", %{user: _user}) do
    %{message: "A link to confirm your e-mail change has been sent to the new address."}
  end

  def render("update_email.json", %{email_changeset: changeset}) do
    %{errors: DemoWeb.ErrorHelpers.error_codes(changeset)}
  end

  def render("confirm_email.json", %{error: error}) do
    %{error: error}
  end

  def render("confirm_email.json", _) do
    %{message: "E-mail changed successfully."}
  end

  def render("update_password.json", %{user: user, token: token}) do
    %{
      user: %{email: user.email},
      token: Base.url_encode64(token)
    }
  end

  def render("update_password.json", %{password_changeset: changeset}) do
    %{errors: DemoWeb.ErrorHelpers.error_codes(changeset)}
  end
end
