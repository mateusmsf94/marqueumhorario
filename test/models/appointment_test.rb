require "test_helper"

class AppointmentTest < ActiveSupport::TestCase
  setup do
    @provider = users(:provider_maria)
    @customer = users(:customer_julia)
    @office = offices(:main_office)
  end

  test "fixture is valid" do
    # TODO: replace fixture-based assertion when factories are added
    assert appointments(:confirmed_oct_first).valid?
  end

  test "end datetime must be after start datetime" do
    start_time = Time.current
    appointment = Appointment.new(
      provider: @provider,
      customer: @customer,
      office: @office,
      status: :pending,
      start_datetime: start_time,
      end_datetime: start_time - 30.minutes,
      book_datetime: start_time - 1.hour
    )

    refute appointment.valid?
    assert_includes appointment.errors[:end_datetime], "must be after start datetime"
  end

  test "book datetime must be before or at start datetime" do
    start_time = Time.current
    appointment = Appointment.new(
      provider: @provider,
      customer: @customer,
      office: @office,
      status: :pending,
      start_datetime: start_time,
      end_datetime: start_time + 30.minutes,
      book_datetime: start_time + 5.minutes
    )

    refute appointment.valid?
    assert_includes appointment.errors[:book_datetime], "must be before or at start datetime"
  end

  test "status enum transitions" do
    appointment = appointments(:confirmed_oct_first)

    assert_equal "confirmed", appointment.status

    appointment.pending!
    appointment.completed!

    assert appointment.completed?
  end

  test "upcoming scope returns future appointments" do
    travel_to Time.zone.local(2025, 9, 30, 8) do
      upcoming = Appointment.upcoming

      assert_includes upcoming, appointments(:confirmed_oct_first)
      assert_includes upcoming, appointments(:confirmed_oct_fifth)
    end
  end

  test "past scope returns appointments that already started" do
    travel_to Time.zone.local(2025, 10, 6, 9) do
      past = Appointment.past

      assert_includes past, appointments(:confirmed_oct_first)
      assert_includes past, appointments(:confirmed_oct_fifth)
    end
  end

  test "by_date scope filters appointments on given day" do
    target_date = Date.new(2025, 10, 1)
    results = Appointment.by_date(target_date)

    assert_includes results, appointments(:confirmed_oct_first)
    refute_includes results, appointments(:confirmed_oct_fifth)
  end

  test "for_user scope returns both provider and customer appointments" do
    provider_results = Appointment.for_user(@provider)
  customer_results = Appointment.for_user(users(:customer_julia))

    assert_includes provider_results, appointments(:confirmed_oct_first)
    refute_includes provider_results, appointments(:confirmed_oct_fifth)

    assert_includes customer_results, appointments(:confirmed_oct_fifth)
  end

  test "for_office scope returns appointments for the given office" do
    assert_includes Appointment.for_office(@office), appointments(:confirmed_oct_first)
    refute_includes Appointment.for_office(@office), appointments(:confirmed_oct_fifth)
  end

  test "prevents double booking for overlapping provider appointments" do
    travel_to Time.zone.local(2025, 9, 29, 12) do
      overlapping = Appointment.new(
        provider: @provider,
        customer: @customer,
        office: @office,
        status: :pending,
        start_datetime: Time.zone.local(2025, 10, 1, 9, 30),
        end_datetime: Time.zone.local(2025, 10, 1, 10, 30),
        book_datetime: Time.zone.local(2025, 9, 29, 11)
      )

      refute overlapping.valid?
      assert_includes overlapping.errors[:base], "provider is already booked during this time"
    end
  end

  test "prevents double booking for overlapping customer appointments" do
    travel_to Time.zone.local(2025, 9, 29, 12) do
      overlapping = Appointment.new(
        provider: users(:john),
  customer: users(:customer_julia),
  office: offices(:branch_office),
        status: :pending,
        start_datetime: Time.zone.local(2025, 10, 5, 13, 30),
        end_datetime: Time.zone.local(2025, 10, 5, 14, 30),
        book_datetime: Time.zone.local(2025, 9, 29, 11)
      )

      refute overlapping.valid?
      assert_includes overlapping.errors[:base], "customer is already booked during this time"
    end
  end

  test "prevents double booking for overlapping office appointments" do
    travel_to Time.zone.local(2025, 9, 29, 12) do
      overlapping = Appointment.new(
        provider: users(:john),
  customer: users(:customer_julia),
        office: @office,
        status: :pending,
        start_datetime: Time.zone.local(2025, 10, 1, 9, 30),
        end_datetime: Time.zone.local(2025, 10, 1, 10, 30),
        book_datetime: Time.zone.local(2025, 9, 29, 11)
      )

      refute overlapping.valid?
      assert_includes overlapping.errors[:base], "office is already booked during this time"
    end
  end

  test "requires future start datetime on create" do
    travel_to Time.zone.local(2025, 10, 2, 12) do
      appointment = Appointment.new(
        provider: @provider,
        customer: @customer,
        office: @office,
        status: :pending,
        start_datetime: Time.zone.local(2025, 10, 1, 9),
        end_datetime: Time.zone.local(2025, 10, 1, 10),
        book_datetime: Time.zone.local(2025, 9, 30, 12)
      )

      refute appointment.valid?
      assert_includes appointment.errors[:start_datetime], "must be in the future"
    end
  end
end
