class CreateMemberships < ActiveRecord::Migration[8.0]
  def change
    create_table :memberships do |t|
      t.references :user, null: false, foreign_key: true
      t.references :office, null: false, foreign_key: true
      t.integer :role, null: false, default: 3

      t.timestamps
    end

    add_index memberships, :role
    add_index memberships, [ :office_id, :role ]
    add_index memberships, [ :user_id, :office_id ], unique: true
  end
end
