class ChangeRoleToIntegerInMemberships < ActiveRecord::Migration[8.0]
  def up
    # Remove existing indexes on role column
    remove_index :memberships, :role
    remove_index :memberships, [ :office_id, :role ]

    # Change column type from string to integer with default for 'customer' (3)
    change_column :memberships, :role, :integer, null: false, default: 3

    # Re-add indexes
    add_index :memberships, :role
    add_index :memberships, [ :office_id, :role ]
  end

  def down
    # Remove indexes
    remove_index :memberships, :role
    remove_index :memberships, [ :office_id, :role ]

    # Change back to string
    change_column :memberships, :role, :string, null: false, default: "customer"

    # Re-add indexes
    add_index :memberships, :role
    add_index :memberships, [ :office_id, :role ]
  end
end
