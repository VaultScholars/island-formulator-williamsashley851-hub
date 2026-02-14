class UsersController < ApplicationController
  # Allow unauthenticated users to sign up
  allow_unauthenticated_access only: %i[new create]

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)

    if @user.save
      # Automatically log in the user after signup
      session = @user.sessions.create!
      cookies.signed[:session_id] = { value: session.id, httponly: true }
      
      redirect_to root_path, notice: "Welcome! Your account has been created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    # Require password confirmation for security
    params.require(:user).permit(:email_address, :password, :password_confirmation)
  end
end