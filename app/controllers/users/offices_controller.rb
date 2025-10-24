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
    # Get the day of week (sunday, monday, etc.)
    day_name = date.strftime("%A").downcase

    # Get working plan for this day
    day_config = @office.working_plan.dig("days", day_name)

    # Return empty if office is closed this day
    return [] unless day_config && day_config["enabled"]

    # Parse working hours
    start_time_str = day_config["start"]
    end_time_str = day_config["end"]
    slot_duration = @office.time_slot_duration.minutes

    # Get breaks for this day
    breaks = @office.working_plan.dig("breaks", day_name) || []

    slots = []
    current_time = Time.zone.parse("#{date} #{start_time_str}")
    end_time = Time.zone.parse("#{date} #{end_time_str}")

    # Generate all possible slots for the day
    while current_time + slot_duration <= end_time
      slot_end = current_time + slot_duration

      # Check if slot overlaps with any break period
      in_break = breaks.any? do |break_period|
        break_start = Time.zone.parse("#{date} #{break_period['start']}")
        break_end = Time.zone.parse("#{date} #{break_period['end']}")
        current_time < break_end && slot_end > break_start
      end

      # Skip slots that fall during break periods
      unless in_break
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
      end

      current_time = slot_end
    end

    slots
  end
end
