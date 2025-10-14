class OfficesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_office, only: [ :show, :edit, :update, :destroy ]
  before_action :authorize_office_access, only: [ :show, :edit, :update, :destroy ]

  def index
    @offices = current_user.offices
  end

  def show
  end

  def new
    @office = Office.new
  end

  def create
    @office = Office.new(office_params)

    if @office.save
      # Create membership making the current user the owner
      @office.memberships.create(user: current_user, role: :owner)
      redirect_to offices_path, notice: "Office was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @office.update(office_params)
      redirect_to @office, notice: "Office was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @office.destroy
    redirect_to offices_path, notice: "Office was successfully deleted."
  end

  private

  def set_office
    @office = Office.find(params[:id])
  end

  def authorize_office_access
    membership = @office.memberships.find_by(user: current_user)
    unless membership&.has_admin_access
      redirect_to offices_path, alert: "You don't have permission to access this office."
    end
  end

  def office_params
    params.require(:office).permit(:name, :address, :city, :state, :zip_code, :phone_number, :gmaps_url)
  end
end
