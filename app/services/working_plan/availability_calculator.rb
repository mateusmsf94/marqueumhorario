# frozen_string_literal: true

module WorkingPlan
  class AvailabilityCalculator
    def self.call(office:, date:, provider: nil)
      new(office: office, date: date, provider: provider).call
    end

    def initialize(office:, date:, provider: nil)
      @office = office
      @date = date.to_date
      @provider = provider
    end

    def call
      # Generate all possible time slots for the day
      slots = TimeSlotGenerator.call(office: @office, date: @date)

      # Return early if no slots are available
      return [] if slots.empty?

      # Fetch all appointments for the date in a single query
      appointments = fetch_appointments_for_date

      # Enrich each slot with availability information
      slots.map do |slot|
        slot.merge(
          available: slot_available?(slot, appointments),
          appointment: find_conflicting_appointment(slot, appointments)
        )
      end
    end

    private

    def fetch_appointments_for_date
      scope = Appointment
        .where(office: @office)
        .where.not(status: :cancelled)
        .by_date(@date)

      # If provider is specified, filter by provider
      scope = scope.where(provider: @provider) if @provider

      scope.to_a
    end

    def slot_available?(slot, appointments)
      # Slot must be in the future
      return false if slot[:start_time] <= Time.current

      # Check if any appointment conflicts with this slot
      !appointments.any? { |appointment| overlaps?(slot, appointment) }
    end

    def find_conflicting_appointment(slot, appointments)
      appointments.find { |appointment| overlaps?(slot, appointment) }
    end

    def overlaps?(slot, appointment)
      # Two time ranges overlap if:
      # slot_start < appointment_end AND slot_end > appointment_start
      slot[:start_time] < appointment.end_datetime &&
        slot[:end_time] > appointment.start_datetime
    end
  end
end
