class Users::OfficesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_provider_and_office

  def show
    @appointment = Appointment.new
    @selected_date = params[:date]&.to_date || Date.current
    @available_slots = generate_available_slots(@selected_date)
  end

  private

  def set_provider_and_office
    @provider = User.find(params[:user_id])
    @office = @provider.offices.find(params[:id])
  end

  def generate_available_slots(date)
    WorkingPlan::AvailabilityCalculator.call(
      office: @office,
      provider: @provider,
      date: date
    )
  end
end
