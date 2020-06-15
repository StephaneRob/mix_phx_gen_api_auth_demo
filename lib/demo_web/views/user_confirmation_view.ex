defmodule DemoWeb.UserConfirmationView do
  use DemoWeb, :view

  def render("create.json", _) do
    %{
      message:
        "If your e-mail is in our system and it has not been confirmed yet, " <>
          "you will receive an e-mail with instructions shortly."
    }
  end

  def render("confirm.json", %{error: error}) do
    %{error: error}
  end

  def render("confirm.json", _) do
    %{message: "Account confirmed successfully."}
  end
end
