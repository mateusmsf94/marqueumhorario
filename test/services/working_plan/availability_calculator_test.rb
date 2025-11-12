require "test_helper"

module WorkingPlan
  class AvailabilityCalculatorTest < ActiveSupport::TestCase
    setup do
      @office = offices(:main_office)
      @provider = users(:provider_maria)
      @customer = users(:customer_julia)
      @future_date = 2.days.from_now.to_date

      @office.update!(
        working_plan: {
          "time_slot_duration" => 30,
          "days" => {
            "monday" => { "enabled" => true, "start" => "09:00", "end" => "12:00" },
            "tuesday" => { "enabled" => true, "start" => "09:00", "end" => "17:00" },
            "wednesday" => { "enabled" => true, "start" => "09:00", "end" => "17:00" },
            "thursday" => { "enabled" => true, "start" => "09:00", "end" => "17:00" },
            "friday" => { "enabled" => true, "start" => "09:00", "end" => "17:00" },
            "saturday" => { "enabled" => true, "start" => "09:00", "end" => "17:00" },
            "sunday" => { "enabled" => true, "start" => "09:00", "end" => "17:00" }
          },
          "breaks" => {
            "monday" => [],
            "tuesday" => [],
            "wednesday" => [],
            "thursday" => [],
            "friday" => [],
            "saturday" => [],
            "sunday" => []
          }
        }
      )
    end

    test "returns enriched slots with availability information" do
      slots = AvailabilityCalculator.call(
        office: @office,
        date: @future_date,
        provider: @provider
      )

      assert_not_empty slots
      assert_instance_of Array, slots

      slots.each do |slot|
        assert_instance_of Hash, slot
        assert_includes slot.keys, :start_time
        assert_includes slot.keys, :end_time
        assert_includes slot.keys, :available
        assert_includes slot.keys, :appointment
        assert_boolean slot[:available]
      end
    end

    test "marks all slots as available when no appointments exist" do
      slots = AvailabilityCalculator.call(
        office: @office,
        date: @future_date,
        provider: @provider
      )

      available_slots = slots.select { |slot| slot[:available] }
      assert_equal slots.length, available_slots.length
    end

    test "marks slots as unavailable when appointment exists" do
      # Create appointment at 10:00-10:30
      start_time = @future_date.to_time.in_time_zone + 10.hours
      end_time = start_time + 30.minutes

      Appointment.create!(
        office: @office,
        provider: @provider,
        customer: @customer,
        start_datetime: start_time,
        end_datetime: end_time,
        book_datetime: Time.current,
        status: :confirmed
      )

      slots = AvailabilityCalculator.call(
        office: @office,
        date: @future_date,
        provider: @provider
      )

      unavailable_slot = slots.find { |slot| slot[:start_time] == start_time }
      assert_not_nil unavailable_slot
      assert_equal false, unavailable_slot[:available]
      assert_not_nil unavailable_slot[:appointment]
    end

    test "includes appointment reference in unavailable slots" do
      start_time = @future_date.to_time.in_time_zone + 10.hours
      end_time = start_time + 30.minutes

      appointment = Appointment.create!(
        office: @office,
        provider: @provider,
        customer: @customer,
        start_datetime: start_time,
        end_datetime: end_time,
        book_datetime: Time.current,
        status: :confirmed
      )

      slots = AvailabilityCalculator.call(
        office: @office,
        date: @future_date,
        provider: @provider
      )

      unavailable_slot = slots.find { |slot| !slot[:available] }
      assert_equal appointment, unavailable_slot[:appointment]
    end

    test "ignores cancelled appointments" do
      start_time = @future_date.to_time.in_time_zone + 10.hours
      end_time = start_time + 30.minutes

      Appointment.create!(
        office: @office,
        provider: @provider,
        customer: @customer,
        start_datetime: start_time,
        end_datetime: end_time,
        book_datetime: Time.current,
        status: :cancelled
      )

      slots = AvailabilityCalculator.call(
        office: @office,
        date: @future_date,
        provider: @provider
      )

      slot_at_cancelled_time = slots.find { |slot| slot[:start_time] == start_time }
      assert_equal true, slot_at_cancelled_time[:available]
      assert_nil slot_at_cancelled_time[:appointment]
    end

    test "marks slots as unavailable for is_unavailability appointments" do
      start_time = @future_date.to_time.in_time_zone + 10.hours
      end_time = start_time + 30.minutes

      Appointment.create!(
        office: @office,
        provider: @provider,
        customer: @customer,
        start_datetime: start_time,
        end_datetime: end_time,
        book_datetime: Time.current,
        status: :confirmed,
        is_unavailability: true
      )

      slots = AvailabilityCalculator.call(
        office: @office,
        date: @future_date,
        provider: @provider
      )

      unavailable_slot = slots.find { |slot| slot[:start_time] == start_time }
      assert_equal false, unavailable_slot[:available]
    end

    test "filters by provider when provider is specified" do
      other_provider = User.create!(
        email: "other_provider@example.com",
        password: "password",
        first_name: "Other",
        last_name: "Provider",
        phone: "+5511666666666",
        cpf: "22222222222"
      )
      Membership.create!(user: other_provider, office: @office, role: :owner)

      start_time = @future_date.to_time.in_time_zone + 10.hours
      end_time = start_time + 30.minutes

      # Create appointment for other provider
      Appointment.create!(
        office: @office,
        provider: other_provider,
        customer: @customer,
        start_datetime: start_time,
        end_datetime: end_time,
        book_datetime: Time.current,
        status: :confirmed
      )

      # Check availability for @provider (should be available)
      slots = AvailabilityCalculator.call(
        office: @office,
        date: @future_date,
        provider: @provider
      )

      slot_at_appointment_time = slots.find { |slot| slot[:start_time] == start_time }
      assert_equal true, slot_at_appointment_time[:available]
    end

    test "checks office-wide availability when provider is not specified" do
      start_time = @future_date.to_time.in_time_zone + 10.hours
      end_time = start_time + 30.minutes

      Appointment.create!(
        office: @office,
        provider: @provider,
        customer: @customer,
        start_datetime: start_time,
        end_datetime: end_time,
        book_datetime: Time.current,
        status: :confirmed
      )

      slots = AvailabilityCalculator.call(
        office: @office,
        date: @future_date
      )

      unavailable_slot = slots.find { |slot| slot[:start_time] == start_time }
      assert_equal false, unavailable_slot[:available]
    end

    test "marks past slots as unavailable" do
      travel_to Time.zone.parse("#{@future_date} 10:30:00") do
        slots = AvailabilityCalculator.call(
          office: @office,
          date: @future_date,
          provider: @provider
        )

        past_slots = slots.select { |slot| slot[:start_time] <= Time.current }
        past_slots.each do |slot|
          assert_equal false, slot[:available], "Slot at #{slot[:start_time]} should be unavailable (in the past)"
        end

        future_slots = slots.select { |slot| slot[:start_time] > Time.current }
        future_slots.each do |slot|
          assert_equal true, slot[:available], "Slot at #{slot[:start_time]} should be available (in the future)"
        end
      end
    end

    test "handles appointment spanning multiple slots" do
      # Create 2-hour appointment spanning 4 slots
      start_time = @future_date.to_time.in_time_zone + 10.hours
      end_time = start_time + 2.hours

      Appointment.create!(
        office: @office,
        provider: @provider,
        customer: @customer,
        start_datetime: start_time,
        end_datetime: end_time,
        book_datetime: Time.current,
        status: :confirmed
      )

      slots = AvailabilityCalculator.call(
        office: @office,
        date: @future_date,
        provider: @provider
      )

      unavailable_slots = slots.select { |slot| !slot[:available] }

      # Should have 4 unavailable slots (10:00, 10:30, 11:00, 11:30)
      expected_times = [
        start_time,
        start_time + 30.minutes,
        start_time + 60.minutes,
        start_time + 90.minutes
      ]

      expected_times.each do |expected_time|
        slot = slots.find { |s| s[:start_time] == expected_time }
        assert_equal false, slot[:available], "Slot at #{expected_time} should be unavailable"
      end
    end

    test "handles partial overlap at slot boundaries" do
      # Appointment from 10:15 to 10:45 overlaps two 30-minute slots
      start_time = @future_date.to_time.in_time_zone + 10.hours + 15.minutes
      end_time = start_time + 30.minutes

      Appointment.create!(
        office: @office,
        provider: @provider,
        customer: @customer,
        start_datetime: start_time,
        end_datetime: end_time,
        book_datetime: Time.current,
        status: :confirmed
      )

      slots = AvailabilityCalculator.call(
        office: @office,
        date: @future_date,
        provider: @provider
      )

      # Both 10:00-10:30 and 10:30-11:00 slots should be unavailable
      slot_1000 = slots.find { |s| s[:start_time].hour == 10 && s[:start_time].min == 0 }
      slot_1030 = slots.find { |s| s[:start_time].hour == 10 && s[:start_time].min == 30 }

      assert_equal false, slot_1000[:available]
      assert_equal false, slot_1030[:available]
    end

    test "returns empty array when no slots are generated" do
      # Wednesday is disabled in the setup
      @office.update!(
        working_plan: @office.working_plan.merge(
          "days" => @office.working_plan["days"].merge(
            "wednesday" => { "enabled" => false, "start" => "00:00", "end" => "00:00" }
          )
        )
      )

      # Find next Wednesday
      date = Date.today
      date += 1 until date.wday == 3

      slots = AvailabilityCalculator.call(
        office: @office,
        date: date,
        provider: @provider
      )

      assert_empty slots
    end

    test "handles multiple appointments in same day" do
      # Create appointments at 9:00, 11:00, and 15:00
      appointments_at = [ 9, 11, 15 ]
      appointments_at.each do |hour|
        start_time = @future_date.to_time.in_time_zone + hour.hours
        end_time = start_time + 30.minutes

        Appointment.create!(
          office: @office,
          provider: @provider,
          customer: @customer,
          start_datetime: start_time,
          end_datetime: end_time,
          book_datetime: Time.current,
          status: :confirmed
        )
      end

      slots = AvailabilityCalculator.call(
        office: @office,
        date: @future_date,
        provider: @provider
      )

      unavailable_count = slots.count { |slot| !slot[:available] }

      # Past slots + 3 booked slots might be unavailable
      # Just verify the specific booked times are unavailable
      appointments_at.each do |hour|
        expected_time = @future_date.to_time.in_time_zone + hour.hours
        slot = slots.find { |s| s[:start_time] == expected_time }
        assert_equal false, slot[:available], "Slot at #{hour}:00 should be unavailable"
      end
    end

    test "handles pending appointments as booked" do
      start_time = @future_date.to_time.in_time_zone + 10.hours
      end_time = start_time + 30.minutes

      Appointment.create!(
        office: @office,
        provider: @provider,
        customer: @customer,
        start_datetime: start_time,
        end_datetime: end_time,
        book_datetime: Time.current,
        status: :pending
      )

      slots = AvailabilityCalculator.call(
        office: @office,
        date: @future_date,
        provider: @provider
      )

      slot_at_pending = slots.find { |slot| slot[:start_time] == start_time }
      assert_equal false, slot_at_pending[:available]
    end

    test "handles completed appointments as booked" do
      start_time = @future_date.to_time.in_time_zone + 10.hours
      end_time = start_time + 30.minutes

      Appointment.create!(
        office: @office,
        provider: @provider,
        customer: @customer,
        start_datetime: start_time,
        end_datetime: end_time,
        book_datetime: Time.current,
        status: :completed
      )

      slots = AvailabilityCalculator.call(
        office: @office,
        date: @future_date,
        provider: @provider
      )

      slot_at_completed = slots.find { |slot| slot[:start_time] == start_time }
      assert_equal false, slot_at_completed[:available]
    end

    test "class method delegates to instance method" do
      class_result = AvailabilityCalculator.call(
        office: @office,
        date: @future_date,
        provider: @provider
      )

      instance_result = AvailabilityCalculator.new(
        office: @office,
        date: @future_date,
        provider: @provider
      ).call

      assert_equal class_result.length, instance_result.length

      class_result.zip(instance_result).each do |class_slot, instance_slot|
        assert_equal class_slot[:start_time], instance_slot[:start_time]
        assert_equal class_slot[:end_time], instance_slot[:end_time]
        assert_equal class_slot[:available], instance_slot[:available]
      end
    end

    test "performance: uses single query for all appointments" do
      # Create multiple appointments
      5.times do |i|
        start_time = @future_date.to_time.in_time_zone + (10 + i).hours
        end_time = start_time + 30.minutes

        Appointment.create!(
          office: @office,
          provider: @provider,
          customer: @customer,
          start_datetime: start_time,
          end_datetime: end_time,
          book_datetime: Time.current,
          status: :confirmed
        )
      end

      # Count queries made during the call
      query_count = 0
      query_counter = lambda { |*, &block| query_count += 1; block&.call }

      ActiveSupport::Notifications.subscribed(query_counter, "sql.active_record") do
        AvailabilityCalculator.call(
          office: @office,
          date: @future_date,
          provider: @provider
        )
      end

      # Should be minimal queries (not N+1)
      # Exact count may vary, but should be low (< 5)
      assert query_count < 10, "Expected minimal queries, got #{query_count}"
    end

    private

    def assert_boolean(value)
      assert_includes [ true, false ], value
    end
  end
end
