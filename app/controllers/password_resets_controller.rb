class PasswordResetsController < ApplicationController
	before_action :get_user, only: [:edit, :update]
	before_action :valid_user, only: [:edit, :update]
	before_action :check_expiration, only: [:edit, :update]

  def new
  end

  def create
  	@user = User.find_by(email: params[:password_reset][:email].downcase)
  	if @user
  		@user.create_reset_digest
  		@user.send_password_reset_email
  		flash[:info] = "Email sent with password reset instructions"
  		redirect_to root_url
  	else
  		flash.now[:danger] = "Email address not found"
  		render 'new'
  	end
  end

  def edit
  end

  def update
  	if password_blank?
  		flash.now[:danger] = "El password no puede quedarse en blanco"
  		render 'edit'
  	elsif @user.update_attributes(user_params)
  		log_in @user
  		flash[:success] = "El password se ha reiniciado"
  		redirect_to queries_path
  	else
  		render 'edit'
  	end	
  end

  private

  def user_params
  	params.require(:user).permit(:password, :password_confirmation)
  end

  # Returns true if password is blank
  def password_blank?
  	params[:user][:password].blank?
  end

  # Before filters

  # Gets the user that came to this page using the email
  def get_user
  	@user = User.find_by(email: params[:email])
  end

  # Confirms a valid user
  def valid_user
  	unless (@user && @user.activated? && @user.authenticated?(:reset, params[:id]))
  		redirect_to root_url
  	end
  end

  # Check expiration of reset token
  def check_expiration
  	if @user.password_reset_expired?
  		flash[:danger] = "El reinicio de password ha caducado"
  		redirect_to new_password_reset_url
  	end
  end

end
