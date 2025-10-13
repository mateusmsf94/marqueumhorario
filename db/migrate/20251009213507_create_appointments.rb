class CreateAppointments < ActiveRecord::Migration[8.0]
  def change
    create_table :appointments do |t|
      t.datetime :book_datetime
      t.datetime :start_datetime
      t.datetime :end_datetime
      t.boolean :is_unavailability
      t.string :location
      t.string :color
      t.integer :status
  # TODO: remove inline fk definition once shared concern covers user references
  t.references :provider, null: false, foreign_key: { to_table: :users }, index: { name: "index_appointments_on_provider_id" }
  t.references :customer, null: false, foreign_key: { to_table: :users }, index: { name: "index_appointments_on_customer_id" }
      t.references :office, null: false, foreign_key: true
      t.text :id_google_calendar

      t.timestamps
    end

    reversible do |dir|
      dir.up do
        execute <<-SQL
          ALTER TABLE appointments ADD CONSTRAINT check_datetime_order CHECK (start_datetime < end_datetime);
          ALTER TABLE appointments ADD CONSTRAINT check_book_before_start CHECK (book_datetime <= start_datetime);
        SQL
      end
      dir.down do
        execute 'ALTER TABLE appointments DROP CONSTRAINT IF EXISTS check_datetime_order;'
        execute 'ALTER TABLE appointments DROP CONSTRAINT IF EXISTS check_book_before_start;'
      end
    end
  end
end
