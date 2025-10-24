class OfficesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_office, only: [ :show, :edit, :update, :destroy, :working_plan, :update_working_plan ]
  before_action :authorize_office_access, only: [ :show, :edit, :update, :destroy, :working_plan, :update_working_plan ]

  def index
    @offices = current_user.offices
  end

  def show
  end

  def new
    @office = Office.new
  end

  def create
    @office = Office.new(office_params)

    if @office.save
      # Create membership making the current user the owner
      @office.memberships.create(user: current_user, role: :owner)
      redirect_to working_plan_office_path(@office), notice: "Office was successfully created. Now configure the working plan."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @office.update(office_params)
      redirect_to @office, notice: "Office was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @office.destroy
    redirect_to offices_path, notice: "Office was successfully deleted."
  end

  def working_plan
  end

  def update_working_plan
    if @office.update(working_plan_params)
      redirect_to offices_path, notice: "Working plan was successfully configured."
    else
      render :working_plan, status: :unprocessable_entity
    end
  end

  private

  def set_office
    @office = Office.find(params[:id])
  end

  def authorize_office_access
    membership = @office.memberships.find_by(user: current_user)
    unless membership&.has_admin_access
      redirect_to offices_path, alert: "You don't have permission to access this office."
    end
  end

  def office_params
    params.require(:office).permit(:name, :address, :city, :state, :zip_code, :phone_number, :gmaps_url)
  end

  def working_plan_params
    # Extract and reconstruct working_plan from params
    working_plan_data = params.require(:office)[:working_plan]

    # Extract time slot duration
    time_slot_duration = working_plan_data[:time_slot_duration].to_i

    # Build the working_plan hash
    days = {}
    breaks = {}

    %w[sunday monday tuesday wednesday thursday friday saturday].each do |day|
      day_params = working_plan_data.dig(:days, day.to_sym)
      if day_params
        days[day] = {
          "enabled" => day_params[:enabled] == "1",
          "start" => day_params[:start],
          "end" => day_params[:end]
        }
      end

      # Handle breaks for each day
      break_params = working_plan_data.dig(:breaks, day.to_sym)
      if break_params.is_a?(Array)
        breaks[day] = break_params.map do |break_data|
          { "start" => break_data[:start], "end" => break_data[:end] }
        end
      elsif break_params.is_a?(Hash)
        breaks[day] = break_params.values.map do |break_data|
          { "start" => break_data[:start], "end" => break_data[:end] }
        end
      else
        breaks[day] = []
      end
    end

    {
      working_plan: {
        "time_slot_duration" => time_slot_duration,
        "days" => days,
        "breaks" => breaks
      }
    }
  end
end
