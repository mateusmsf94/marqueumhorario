class Membership < ApplicationRecord
  belongs_to :user
  belongs_to :office

  enum :role, { owner: 0, co_owner: 1, secretary: 2 }

  validates :user_id, uniqueness: { scope: :office_id }
  before_destroy :ensure_owner_remains

  def has_admin_access
    owner? || co_owner? || secretary?
  end

  private

  def ensure_owner_remains
    if owner? && office.memberships.where(role: :owner).count == 1
      errors.add(:base, "Cannot remove the last owner of an office")
      throw(:abort)
    end
  end
end
