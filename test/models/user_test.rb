require "test_helper"

class UserTest < ActiveSupport::TestCase
  def setup
    @user = users(:john)
  end

  test "should be a valid user" do
    assert @user.valid?
  end
end
