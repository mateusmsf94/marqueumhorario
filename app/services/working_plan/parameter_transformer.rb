# frozen_string_literal: true

module WorkingPlan
  # Transforms form parameters into working plan JSON structure
  #
  # Usage:
  #   working_plan_json = WorkingPlan::ParameterTransformer.call(
  #     params: params[:office]
  #   )
  #
  # Returns: Hash suitable for office.working_plan attribute
  class ParameterTransformer
    DAYS_OF_WEEK = %w[sunday monday tuesday wednesday thursday friday saturday].freeze

    def self.call(params:)
      new(params: params).call
    end

    def initialize(params:)
      @params = params
    end

    def call
      {
        working_plan: {
          "time_slot_duration" => extract_time_slot_duration,
          "days" => transform_days,
          "breaks" => transform_breaks
        }
      }
    end

    private

    attr_reader :params

    def working_plan_data
      @working_plan_data ||= params[:working_plan]
    end

    def extract_time_slot_duration
      working_plan_data[:time_slot_duration].to_i
    end

    def transform_days
      DAYS_OF_WEEK.each_with_object({}) do |day, hash|
        day_params = working_plan_data.dig(:days, day.to_sym)
        next unless day_params

        hash[day] = {
          "enabled" => day_params[:enabled] == "1",
          "start" => day_params[:start],
          "end" => day_params[:end]
        }
      end
    end

    def transform_breaks
      DAYS_OF_WEEK.each_with_object({}) do |day, hash|
        hash[day] = extract_breaks_for_day(day)
      end
    end

    def extract_breaks_for_day(day)
      break_params = working_plan_data.dig(:breaks, day.to_sym)

      case break_params
      when Array
        parse_break_array(break_params)
      when Hash
        parse_break_hash(break_params)
      else
        []
      end
    end

    def parse_break_array(break_params)
      break_params.map do |break_data|
        {
          "start" => break_data[:start],
          "end" => break_data[:end]
        }
      end
    end

    def parse_break_hash(break_params)
      break_params.values.map do |break_data|
        {
          "start" => break_data[:start],
          "end" => break_data[:end]
        }
      end
    end
  end
end
