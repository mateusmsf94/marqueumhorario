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
    # Default office hours: 8 AM to 6 PM
    start_hour = 8
    end_hour = 18
    slot_duration = 30.minutes

    slots = []
    current_time = date.beginning_of_day + start_hour.hours

    # Generate all possible slots for the day
    while current_time.hour < end_hour
      slot_end = current_time + slot_duration

      # Check if slot is available (no overlapping appointments)
      is_available = !Appointment
        .where(office: @office, provider: @provider)
        .where.not(status: :cancelled)
        .where("start_datetime < ? AND end_datetime > ?", slot_end, current_time)
        .exists?

      slots << {
        start_time: current_time,
        end_time: slot_end,
        available: is_available && current_time > Time.current
      }

      current_time = slot_end
    end

    slots
  end
end
