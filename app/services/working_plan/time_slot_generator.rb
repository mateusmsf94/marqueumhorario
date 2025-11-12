module WorkingPlan
  class TimeSlotGenerator
    def self.call(office:, date:)
      new(office: office, date: date).call
    end

    def initialize(office:, date:)
      @office = office
      @date = date
    end

    def call
      day_config = working_plan_for_day
      return [] unless day_open?(day_config)
      generate_slots(day_config)
    end

    private

    def working_plan_for_day
      day_name = @date.strftime("%A").downcase
      @office.working_plan.dig("days", day_name)
    end

    def day_open?(day_config)
      day_config && day_config["enabled"]
    end

    def generate_slots(day_config)
      start_time = parse_time(day_config["start"])
      end_time = parse_time(day_config["end"])
      duration = slot_duration

      slots = []
      current_time = start_time

      while current_time + duration <= end_time
        slot_end = current_time + duration

        unless overlaps_with_break?(current_time, slot_end)
          slots << {
            start_time: current_time,
            end_time: slot_end
          }
        end

        current_time = slot_end
      end

      slots
    end

    def parse_time(time_string)
      Time.zone.parse("#{@date} #{time_string}")
    end

    def slot_duration
      @office.time_slot_duration.minutes
    end

    def overlaps_with_break?(slot_start, slot_end)
      breaks_for_day.any? do |break_period|
        break_start = parse_time(break_period["start"])
        break_end = parse_time(break_period["end"])
        slot_start < break_end && slot_end > break_start
      end
    end

    def breaks_for_day
      day_name = @date.strftime("%A").downcase
      @office.working_plan.dig("breaks", day_name) || []
    end
  end
end
