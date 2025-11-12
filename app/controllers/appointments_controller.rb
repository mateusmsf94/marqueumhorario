class AppointmentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_provider_and_office

  def create
    @appointment = Appointment.new(appointment_params)
    @appointment.customer = current_user
    @appointment.provider = @provider
    @appointment.office = @office
    @appointment.book_datetime = Time.current

    if @appointment.save
      redirect_to user_path(@provider), notice: "Appointment booked successfully!"
    else
      # Prepare variables needed by users/offices/show template
      @selected_date = @appointment.start_datetime&.to_date || Date.current
      @available_slots = generate_available_slots(@selected_date)
      render "users/offices/show", status: :unprocessable_entity
    end
  end

  private

  def set_provider_and_office
    @provider = User.find(params[:user_id])
    @office = @provider.offices.find(params[:office_id])
  end

  def appointment_params
    params.require(:appointment).permit(:start_datetime, :end_datetime)
  end

  def generate_available_slots(date)
    WorkingPlan::AvailabilityCalculator.call(
      office: @office,
      provider: @provider,
      date: date
    )
  end
end
