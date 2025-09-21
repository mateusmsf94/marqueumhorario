class Office < ApplicationRecord
  validates :name, presence: true
  validates :address, presence: true
  validates :city, presence: true
  validates :state, presence: true
  validates :zip_code, presence: true

  has_many :memberships
  has_many :users, throught: :membershipsra
end
