require "test_helper"

class MembershipTest < ActiveSupport::TestCase
  test "membership cannot be a customer" do
    user = users(:john)
  office = offices(:main_office)

    # Customer role is not defined in the enum, so this should raise an ArgumentError
    assert_raises(ArgumentError, "'customer' is not a valid role") do
      Membership.new(user: user, office: office, role: :customer)
    end
  end

  test "only allows valid membership roles" do
    # Test that the enum only includes the expected roles
    expected_roles = %w[owner co_owner secretary]
    assert_equal expected_roles, Membership.roles.keys

    # Ensure customer is not in the available roles
    assert_not_includes Membership.roles.keys, "customer"
  end

  test "should allow owner role" do
    user = users(:john)
  office = offices(:main_office)

    membership = Membership.new(user: user, office: office, role: :owner)

    assert membership.valid?
  end

  test "should allow co_owner role" do
    user = users(:john)
  office = offices(:main_office)

    membership = Membership.new(user: user, office: office, role: :co_owner)

    assert membership.valid?
  end

  test "should allow secretary role" do
    user = users(:john)
  office = offices(:main_office)

    membership = Membership.new(user: user, office: office, role: :secretary)

    assert membership.valid?
  end

  test "owner should have admin access" do
  membership = memberships(:main_office_owner) # This is an owner from fixtures

    assert membership.has_admin_access
  end

  test "co_owner should have admin access" do
    user = users(:john)
  office = offices(:main_office)
  membership = Membership.create!(user: user, office: office, role: :co_owner)

    assert membership.has_admin_access
  end

  test "secretary should have admin access" do
    user = users(:john)
  office = offices(:main_office)
  membership = Membership.create!(user: user, office: office, role: :secretary)

    assert membership.has_admin_access
  end

  test "should prevent destroying last owner" do
  office = offices(:main_office)
  owner_membership = memberships(:main_office_owner) # This is the owner

    # Ensure this is the only owner
    assert_equal 1, office.memberships.where(role: :owner).count

    assert_raises(ActiveRecord::RecordNotDestroyed) do
      owner_membership.destroy!
    end
  end

  test "should allow destroying owner when there are multiple owners" do
  office = offices(:main_office)
    user = users(:john)

    # Create another owner
    Membership.create!(user: user, office: office, role: :owner)

  # Now we should be able to destroy one of them
  owner_membership = memberships(:main_office_owner)

    assert owner_membership.destroy
  end

  test "should enforce unique user per office" do
  existing_membership = memberships(:main_office_owner)
    duplicate_membership = Membership.new(
      user: existing_membership.user,
      office: existing_membership.office,
      role: :secretary
    )

    assert_not duplicate_membership.valid?
    assert_includes duplicate_membership.errors[:user_id], "has already been taken"
  end
end
