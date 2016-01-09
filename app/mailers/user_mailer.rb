class UserMailer < ApplicationMailer

  def account_activation(user)
    @user = user
    mail to: user.email, subject: "Activación de cuenta"
  end

  def password_reset(user)
    @user = user
    mail to: user.email, subject: "Reinicio password"
  end
end
