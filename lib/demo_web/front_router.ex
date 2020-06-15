defmodule DemoWeb.FrontRouter do
  def user_reset_password_url(token) do
    "/users/reset_password/#{token}"
  end

  def user_confirmation_url(token) do
    "/users/confirm/#{token}"
  end

  def user_settings_url(token) do
    "/users/settings/confirm_email/#{token}"
  end
end
