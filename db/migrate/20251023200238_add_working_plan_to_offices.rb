class AddWorkingPlanToOffices < ActiveRecord::Migration[8.0]
  def change
    add_column :offices, :working_plan, :jsonb, default: {}, null: false
  end
end
