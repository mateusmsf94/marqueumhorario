require "test_helper"

module WorkingPlan
  class ParameterTransformerTest < ActiveSupport::TestCase
    test "transforms basic working plan parameters" do
      params = build_params(
        time_slot_duration: "30",
        days: {
          monday: { enabled: "1", start: "09:00", end: "17:00" },
          tuesday: { enabled: "1", start: "10:00", end: "18:00" },
          wednesday: { enabled: "0", start: "09:00", end: "17:00" }
        },
        breaks: {
          monday: [],
          tuesday: [],
          wednesday: []
        }
      )

      result = ParameterTransformer.call(params: params)

      assert_equal 30, result[:working_plan]["time_slot_duration"]
      assert_equal true, result[:working_plan]["days"]["monday"]["enabled"]
      assert_equal "09:00", result[:working_plan]["days"]["monday"]["start"]
      assert_equal "17:00", result[:working_plan]["days"]["monday"]["end"]
      assert_equal true, result[:working_plan]["days"]["tuesday"]["enabled"]
      assert_equal false, result[:working_plan]["days"]["wednesday"]["enabled"]
    end

    test "transforms breaks as array" do
      params = build_params(
        time_slot_duration: "30",
        days: {
          monday: { enabled: "1", start: "09:00", end: "17:00" }
        },
        breaks: {
          monday: [
            { start: "12:00", end: "13:00" },
            { start: "15:00", end: "15:30" }
          ]
        }
      )

      result = ParameterTransformer.call(params: params)

      monday_breaks = result[:working_plan]["breaks"]["monday"]
      assert_equal 2, monday_breaks.length
      assert_equal "12:00", monday_breaks[0]["start"]
      assert_equal "13:00", monday_breaks[0]["end"]
      assert_equal "15:00", monday_breaks[1]["start"]
      assert_equal "15:30", monday_breaks[1]["end"]
    end

    test "transforms breaks as hash (from form params)" do
      params = build_params(
        time_slot_duration: "30",
        days: {
          monday: { enabled: "1", start: "09:00", end: "17:00" }
        },
        breaks: {
          monday: {
            "0" => { start: "12:00", end: "13:00" },
            "1" => { start: "15:00", end: "15:30" }
          }
        }
      )

      result = ParameterTransformer.call(params: params)

      monday_breaks = result[:working_plan]["breaks"]["monday"]
      assert_equal 2, monday_breaks.length
      assert_includes monday_breaks, { "start" => "12:00", "end" => "13:00" }
      assert_includes monday_breaks, { "start" => "15:00", "end" => "15:30" }
    end

    test "handles missing breaks gracefully" do
      params = build_params(
        time_slot_duration: "30",
        days: {
          monday: { enabled: "1", start: "09:00", end: "17:00" }
        },
        breaks: {
          monday: nil
        }
      )

      result = ParameterTransformer.call(params: params)

      assert_equal [], result[:working_plan]["breaks"]["monday"]
    end

    test "transforms all days of the week" do
      params = build_params(
        time_slot_duration: "45",
        days: {
          sunday: { enabled: "1", start: "10:00", end: "14:00" },
          monday: { enabled: "1", start: "09:00", end: "17:00" },
          tuesday: { enabled: "1", start: "09:00", end: "17:00" },
          wednesday: { enabled: "1", start: "09:00", end: "17:00" },
          thursday: { enabled: "1", start: "09:00", end: "17:00" },
          friday: { enabled: "1", start: "09:00", end: "17:00" },
          saturday: { enabled: "0", start: "00:00", end: "00:00" }
        },
        breaks: {
          sunday: [],
          monday: [],
          tuesday: [],
          wednesday: [],
          thursday: [],
          friday: [],
          saturday: []
        }
      )

      result = ParameterTransformer.call(params: params)

      days = result[:working_plan]["days"]
      assert_equal 7, days.keys.length
      assert_includes days.keys, "sunday"
      assert_includes days.keys, "monday"
      assert_includes days.keys, "tuesday"
      assert_includes days.keys, "wednesday"
      assert_includes days.keys, "thursday"
      assert_includes days.keys, "friday"
      assert_includes days.keys, "saturday"

      assert_equal true, days["sunday"]["enabled"]
      assert_equal false, days["saturday"]["enabled"]
    end

    test "converts time slot duration to integer" do
      params = build_params(
        time_slot_duration: "60",
        days: { monday: { enabled: "1", start: "09:00", end: "17:00" } },
        breaks: { monday: [] }
      )

      result = ParameterTransformer.call(params: params)

      assert_equal 60, result[:working_plan]["time_slot_duration"]
      assert_instance_of Integer, result[:working_plan]["time_slot_duration"]
    end

    test "properly formats enabled flag as boolean" do
      params = build_params(
        time_slot_duration: "30",
        days: {
          monday: { enabled: "1", start: "09:00", end: "17:00" },
          tuesday: { enabled: "0", start: "09:00", end: "17:00" }
        },
        breaks: {
          monday: [],
          tuesday: []
        }
      )

      result = ParameterTransformer.call(params: params)

      assert_equal true, result[:working_plan]["days"]["monday"]["enabled"]
      assert_equal false, result[:working_plan]["days"]["tuesday"]["enabled"]
      assert_instance_of TrueClass, result[:working_plan]["days"]["monday"]["enabled"]
      assert_instance_of FalseClass, result[:working_plan]["days"]["tuesday"]["enabled"]
    end

    test "handles complex scenario with multiple breaks across days" do
      params = build_params(
        time_slot_duration: "30",
        days: {
          monday: { enabled: "1", start: "09:00", end: "18:00" },
          wednesday: { enabled: "1", start: "08:00", end: "16:00" },
          friday: { enabled: "0", start: "00:00", end: "00:00" }
        },
        breaks: {
          monday: [
            { start: "12:00", end: "13:00" },
            { start: "15:00", end: "15:15" }
          ],
          wednesday: {
            "0" => { start: "10:00", end: "10:30" }
          },
          friday: []
        }
      )

      result = ParameterTransformer.call(params: params)

      # Check time slot duration
      assert_equal 30, result[:working_plan]["time_slot_duration"]

      # Check days
      assert_equal true, result[:working_plan]["days"]["monday"]["enabled"]
      assert_equal "09:00", result[:working_plan]["days"]["monday"]["start"]
      assert_equal "18:00", result[:working_plan]["days"]["monday"]["end"]

      assert_equal true, result[:working_plan]["days"]["wednesday"]["enabled"]
      assert_equal "08:00", result[:working_plan]["days"]["wednesday"]["start"]

      assert_equal false, result[:working_plan]["days"]["friday"]["enabled"]

      # Check breaks
      monday_breaks = result[:working_plan]["breaks"]["monday"]
      assert_equal 2, monday_breaks.length
      assert_equal "12:00", monday_breaks[0]["start"]
      assert_equal "13:00", monday_breaks[0]["end"]

      wednesday_breaks = result[:working_plan]["breaks"]["wednesday"]
      assert_equal 1, wednesday_breaks.length
      assert_equal "10:00", wednesday_breaks[0]["start"]
      assert_equal "10:30", wednesday_breaks[0]["end"]

      friday_breaks = result[:working_plan]["breaks"]["friday"]
      assert_equal [], friday_breaks
    end

    private

    def build_params(time_slot_duration:, days:, breaks:)
      {
        working_plan: {
          time_slot_duration: time_slot_duration,
          days: days,
          breaks: breaks
        }
      }
    end
  end
end
