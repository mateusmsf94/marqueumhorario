require "test_helper"

class AppointmentTest < ActiveSupport::TestCase
  setup do
    @provider = users(:one)
    @customer = users(:two)
    @office = offices(:one)
  end

  test "fixture is valid" do
    # TODO: replace fixture-based assertion when factories are added
    assert appointments(:one).valid?
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
    appointment = appointments(:one)

    assert_equal "confirmed", appointment.status

    appointment.pending!
    appointment.completed!

    assert appointment.completed?
  end
end
