class Office < ApplicationRecord
  has_many :memberships
  has_many :users, throught: :membershipsra
end
