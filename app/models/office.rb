class Office < ApplicationRecord
  validates :name, presence: true
  validates :address, presence: true
  validates :city, presence: true
  validates :state, presence: true
  validates :zip_code, presence: true

  validate :must_have_at_least_one_owner, unless: :new_record?

  private

  def must_have_at_least_one_owner
    current_memberships = memberships.reject(&:marked_for_destruction?)
    return if current_memberships.any?(&:owner?)
      errors.add(:base, "Office must have at least one owner")
  end

  has_many :memberships
  has_many :users, through: :memberships
  has_many :appointments, dependent: :destroy
end
