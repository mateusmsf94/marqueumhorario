class AddRoleToMemberships < ActiveRecord::Migration[8.0]
  def change
    add_column :memberships, :role, :integer, null: false, default: 3
    add_index :memberships, :role
    add_index :memberships, [ :office_id, :role ]
    add_index :memberships, [ :user_id, :office_id ], unique: true
  end
end
