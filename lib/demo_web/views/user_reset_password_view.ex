defmodule DemoWeb.UserResetPasswordView do
  use DemoWeb, :view

  def render("create.json", _) do
    %{
      message:
        "If your e-mail is in our system, you will receive instructions to reset your password shortly."
    }
  end

  def render("update.json", %{changeset: changeset}) do
    %{errors: DemoWeb.ErrorHelpers.error_codes(changeset)}
  end

  def render("update.json", _) do
    %{message: "Password reset successfully"}
  end
end
