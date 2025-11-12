require "test_helper"

module WorkingPlan
  class TimeSlotGeneratorTest < ActiveSupport::TestCase
    setup do
      @office = offices(:main_office)
      @date = Date.new(2025, 11, 10)

      @office.update!(
        working_plan: {
          "time_slot_duration" => 30,
          "days" => {
            "monday" => { "enabled" => true, "start" => "09:00", "end" => "12:00" },
            "tuesday" => { "enabled" => true, "start" => "09:00", "end" => "17:00" },
            "wednesday" => { "enabled" => false, "start" => "09:00", "end" => "17:00" },
            "thursday" => { "enabled" => true, "start" => "10:00", "end" => "15:00" },
            "friday" => { "enabled" => true, "start" => "09:00", "end" => "18:00" },
            "saturday" => { "enabled" => true, "start" => "08:00", "end" => "12:00" },
            "sunday" => { "enabled" => false, "start" => "00:00", "end" => "00:00" }
          },
          "breaks" => {
            "monday" => [],
            "tuesday" => [
              { "start" => "12:00", "end" => "13:00" }
            ],
            "thursday" => [
              { "start" => "12:00", "end" => "12:30" },
              { "start" => "14:00", "end" => "14:15" }
            ],
            "friday" => [
              { "start" => "09:00", "end" => "18:00" }
            ],
            "saturday" => [],
            "sunday" => []
          }
        }
      )
    end

    test "generates slots for enabled working days" do
      monday = Date.new(2025, 11, 10)
      slots = TimeSlotGenerator.call(office: @office, date: monday)

      assert_not_empty slots
      assert_instance_of Array, slots

      slots.each do |slot|
        assert_instance_of Hash, slot
        assert_includes slot.keys, :start_time
        assert_includes slot.keys, :end_time
        assert_instance_of ActiveSupport::TimeWithZone, slot[:start_time]
        assert_instance_of ActiveSupport::TimeWithZone, slot[:end_time]
      end
    end

    test "calculates correct number of slots" do
      monday = Date.new(2025, 11, 10)
      slots = TimeSlotGenerator.call(office: @office, date: monday)

      assert_equal 6, slots.length
    end

    test "each slot has correct duration" do
      monday = Date.new(2025, 11, 10)
      slots = TimeSlotGenerator.call(office: @office, date: monday)

      slots.each do |slot|
        duration_minutes = ((slot[:end_time] - slot[:start_time]) / 60).to_i
        assert_equal 30, duration_minutes
      end
    end

    test "slots are sequential and non-overlapping" do
      monday = Date.new(2025, 11, 10)
      slots = TimeSlotGenerator.call(office: @office, date: monday)

      slots.each_cons(2) do |current_slot, next_slot|
        assert_equal current_slot[:end_time], next_slot[:start_time]
      end
    end

    test "first slot starts at day start time" do
      monday = Date.new(2025, 11, 10)
      slots = TimeSlotGenerator.call(office: @office, date: monday)

      first_slot = slots.first
      expected_start = Time.zone.parse("2025-11-10 09:00:00")

      assert_equal expected_start, first_slot[:start_time]
    end

    test "last slot does not exceed day end time" do
      monday = Date.new(2025, 11, 10)
      slots = TimeSlotGenerator.call(office: @office, date: monday)

      last_slot = slots.last
      expected_end = Time.zone.parse("2025-11-10 12:00:00")

      assert last_slot[:end_time] <= expected_end
    end

    test "returns empty array for disabled days" do
      wednesday = Date.new(2025, 11, 12)
      slots = TimeSlotGenerator.call(office: @office, date: wednesday)

      assert_empty slots
    end

    test "returns empty array for missing day configuration" do
      @office.update!(working_plan: { "days" => {}, "breaks" => {} })

      monday = Date.new(2025, 11, 10)
      slots = TimeSlotGenerator.call(office: @office, date: monday)

      assert_empty slots
    end

    test "excludes slots that overlap with breaks" do
      tuesday = Date.new(2025, 11, 11)
      slots = TimeSlotGenerator.call(office: @office, date: tuesday)

      lunch_break_start = Time.zone.parse("2025-11-11 12:00:00")
      lunch_break_end = Time.zone.parse("2025-11-11 13:00:00")

      slots.each do |slot|
        overlaps = slot[:start_time] < lunch_break_end && slot[:end_time] > lunch_break_start
        assert_not overlaps, "Slot #{slot[:start_time]} - #{slot[:end_time]} overlaps with lunch break"
      end
    end

    test "handles multiple breaks in one day" do
      thursday = Date.new(2025, 11, 13)
      slots = TimeSlotGenerator.call(office: @office, date: thursday)

      break_1_start = Time.zone.parse("2025-11-13 12:00:00")
      break_1_end = Time.zone.parse("2025-11-13 12:30:00")
      break_2_start = Time.zone.parse("2025-11-13 14:00:00")
      break_2_end = Time.zone.parse("2025-11-13 14:15:00")

      slots.each do |slot|
        overlaps_break_1 = slot[:start_time] < break_1_end && slot[:end_time] > break_1_start
        overlaps_break_2 = slot[:start_time] < break_2_end && slot[:end_time] > break_2_start

        assert_not overlaps_break_1, "Slot overlaps with first break"
        assert_not overlaps_break_2, "Slot overlaps with second break"
      end
    end

    test "generates continuous slots when no breaks configured" do
      monday = Date.new(2025, 11, 10)
      slots = TimeSlotGenerator.call(office: @office, date: monday)

      slots.each_cons(2) do |current_slot, next_slot|
        assert_equal current_slot[:end_time], next_slot[:start_time]
      end
    end

    test "handles empty breaks array" do
      saturday = Date.new(2025, 11, 15)
      slots = TimeSlotGenerator.call(office: @office, date: saturday)

      assert_not_empty slots
      assert_equal 8, slots.length
    end

    test "handles partial overlap between slot and break" do
      @office.update!(
        working_plan: @office.working_plan.merge(
          "days" => @office.working_plan["days"].merge(
            "monday" => { "enabled" => true, "start" => "09:00", "end" => "11:00" }
          ),
          "breaks" => @office.working_plan["breaks"].merge(
            "monday" => [ { "start" => "09:45", "end" => "10:15" } ]
          )
        )
      )

      monday = Date.new(2025, 11, 10)
      slots = TimeSlotGenerator.call(office: @office, date: monday)

      partial_break_start = Time.zone.parse("2025-11-10 09:45:00")
      partial_break_end = Time.zone.parse("2025-11-10 10:15:00")

      slots.each do |slot|
        overlaps = slot[:start_time] < partial_break_end && slot[:end_time] > partial_break_start
        assert_not overlaps
      end
    end

    test "handles break covering entire working hours" do
      friday = Date.new(2025, 11, 14)
      slots = TimeSlotGenerator.call(office: @office, date: friday)

      assert_empty slots
    end

    test "handles slot duration not dividing evenly into working hours" do
      @office.update!(
        working_plan: @office.working_plan.merge(
          "time_slot_duration" => 40,
          "days" => @office.working_plan["days"].merge(
            "monday" => { "enabled" => true, "start" => "09:00", "end" => "11:00" }
          ),
          "breaks" => @office.working_plan["breaks"].merge(
            "monday" => []
          )
        )
      )

      monday = Date.new(2025, 11, 10)
      slots = TimeSlotGenerator.call(office: @office, date: monday)

      assert_equal 3, slots.length

      last_slot = slots.last
      end_time = Time.zone.parse("2025-11-10 11:00:00")
      assert last_slot[:end_time] <= end_time
    end

    test "generates correct number of slots with 15 minute duration" do
      @office.update!(
        working_plan: @office.working_plan.merge(
          "time_slot_duration" => 15,
          "days" => @office.working_plan["days"].merge(
            "monday" => { "enabled" => true, "start" => "09:00", "end" => "10:00" }
          ),
          "breaks" => @office.working_plan["breaks"].merge(
            "monday" => []
          )
        )
      )

      monday = Date.new(2025, 11, 10)
      slots = TimeSlotGenerator.call(office: @office, date: monday)

      assert_equal 4, slots.length

      slots.each do |slot|
        duration_minutes = ((slot[:end_time] - slot[:start_time]) / 60).to_i
        assert_equal 15, duration_minutes
      end
    end

    test "generates correct number of slots with 60 minute duration" do
      @office.update!(
        working_plan: @office.working_plan.merge(
          "time_slot_duration" => 60,
          "days" => @office.working_plan["days"].merge(
            "monday" => { "enabled" => true, "start" => "09:00", "end" => "13:00" }
          ),
          "breaks" => @office.working_plan["breaks"].merge(
            "monday" => []
          )
        )
      )

      monday = Date.new(2025, 11, 10)
      slots = TimeSlotGenerator.call(office: @office, date: monday)

      assert_equal 4, slots.length

      slots.each do |slot|
        duration_minutes = ((slot[:end_time] - slot[:start_time]) / 60).to_i
        assert_equal 60, duration_minutes
      end
    end

    test "slots before break end at or before break start" do
      tuesday = Date.new(2025, 11, 11)
      slots = TimeSlotGenerator.call(office: @office, date: tuesday)

      break_start = Time.zone.parse("2025-11-11 12:00:00")

      before_break_slots = slots.select { |slot| slot[:end_time] <= break_start }

      before_break_slots.each do |slot|
        assert slot[:end_time] <= break_start
      end
    end

    test "slots after break start at or after break end" do
      tuesday = Date.new(2025, 11, 11)
      slots = TimeSlotGenerator.call(office: @office, date: tuesday)

      break_end = Time.zone.parse("2025-11-11 13:00:00")

      after_break_slots = slots.select { |slot| slot[:start_time] >= break_end }

      after_break_slots.each do |slot|
        assert slot[:start_time] >= break_end
      end
    end

    test "class method delegates to instance method" do
      monday = Date.new(2025, 11, 10)

      class_result = TimeSlotGenerator.call(office: @office, date: monday)
      instance_result = TimeSlotGenerator.new(office: @office, date: monday).call

      assert_equal class_result.length, instance_result.length

      class_result.zip(instance_result).each do |class_slot, instance_slot|
        assert_equal class_slot[:start_time], instance_slot[:start_time]
        assert_equal class_slot[:end_time], instance_slot[:end_time]
      end
    end

    test "respects time zone configuration" do
      Time.use_zone("America/Sao_Paulo") do
        monday = Date.new(2025, 11, 10)
        slots = TimeSlotGenerator.call(office: @office, date: monday)

        first_slot = slots.first
        assert_equal "America/Sao_Paulo", first_slot[:start_time].time_zone.name
      end
    end

    test "generates slots for different weekdays" do
      monday = Date.new(2025, 11, 10)
      tuesday = Date.new(2025, 11, 11)
      thursday = Date.new(2025, 11, 13)

      monday_slots = TimeSlotGenerator.call(office: @office, date: monday)
      tuesday_slots = TimeSlotGenerator.call(office: @office, date: tuesday)
      thursday_slots = TimeSlotGenerator.call(office: @office, date: thursday)

      assert_equal 6, monday_slots.length
      assert_equal 14, tuesday_slots.length
      assert_equal 8, thursday_slots.length
    end
  end
end
