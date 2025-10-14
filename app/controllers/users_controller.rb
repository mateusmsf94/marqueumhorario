class UsersController < ApplicationController
  before_action :authenticate_user!

  def index
    @user = current_user
    @provided_appointments = @user.provided_appointments
    @customer_appointments = @user.customer_appointments
  end

  def show
    @user = User.find(params[:id])
    @offices = @user.offices
  end
end
