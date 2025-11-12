class Office < ApplicationRecord
  validates :name, presence: true
  validates :address, presence: true
  validates :city, presence: true
  validates :state, presence: true
  validates :zip_code, presence: true
  validates :gmaps_url, allow_blank: true, format: {
    with: %r{\Ahttps?://[^\s]+\z}i,
    message: "must be a valid HTTP or HTTPS URL"
  }

  validate :must_have_at_least_one_owner, unless: :new_record?

  has_many :memberships
  has_many :users, through: :memberships
  has_many :appointments, dependent: :destroy

  # Default working plan structure
  DEFAULT_WORKING_PLAN = {
    "time_slot_duration" => 30, # Duration in minutes
    "days" => {
      "sunday" => { "enabled" => true, "start" => "09:00", "end" => "18:00" },
      "monday" => { "enabled" => true, "start" => "09:00", "end" => "18:00" },
      "tuesday" => { "enabled" => true, "start" => "09:00", "end" => "18:00" },
      "wednesday" => { "enabled" => true, "start" => "09:00", "end" => "18:00" },
      "thursday" => { "enabled" => true, "start" => "09:00", "end" => "18:00" },
      "friday" => { "enabled" => true, "start" => "09:00", "end" => "18:00" },
      "saturday" => { "enabled" => true, "start" => "09:00", "end" => "18:00" }
    },
    "breaks" => {
      "sunday" => [ { "start" => "14:30", "end" => "15:00" } ],
      "monday" => [ { "start" => "14:30", "end" => "15:00" } ],
      "tuesday" => [ { "start" => "14:30", "end" => "15:00" } ],
      "wednesday" => [ { "start" => "14:30", "end" => "15:00" } ],
      "thursday" => [ { "start" => "14:30", "end" => "15:00" } ],
      "friday" => [ { "start" => "14:30", "end" => "15:00" } ],
      "saturday" => [ { "start" => "14:30", "end" => "15:00" } ]
    }
  }.freeze

  # Initialize working plan with defaults if empty
  after_initialize :set_default_working_plan, if: :new_record?
  before_validation :set_default_working_plan, on: :create

  def set_default_working_plan
    self.working_plan = DEFAULT_WORKING_PLAN.deep_dup if working_plan.blank? || working_plan == {}
  end

  # Check if working plan has been configured
  def working_plan_configured?
    working_plan.present? && working_plan != DEFAULT_WORKING_PLAN
  end

  # Get time slot duration in minutes
  def time_slot_duration
    working_plan["time_slot_duration"] || 30
  end

  # Generate available time slots for a specific day
  def generate_time_slots_for_day(day_name)
    WorkingPlan::TimeSlotGenerator.call(office: self, date: date)
  end

  # Get all available time slots for the week
  def weekly_time_slots
    %w[sunday monday tuesday wednesday thursday friday saturday].each_with_object({}) do |day, hash|
      hash[day] = generate_time_slots_for_day(day)
    end
  end

  private

  # Parse time string (HH:MM) into Time object for today
  def parse_time(time_string)
    Time.zone.parse("#{Date.current} #{time_string}")
  end

  # Check if a time slot overlaps with any break period
  def overlaps_with_break?(slot_start, slot_end, breaks)
    breaks.any? do |break_period|
      break_start = parse_time(break_period["start"])
      break_end = parse_time(break_period["end"])

      # Check for overlap: slot overlaps if it starts before break ends and ends after break starts
      slot_start < break_end && slot_end > break_start
    end
  end

  def must_have_at_least_one_owner
    current_memberships = memberships.reject(&:marked_for_destruction?)
    return if current_memberships.any?(&:owner?)
      errors.add(:base, "Office must have at least one owner")
  end
end
