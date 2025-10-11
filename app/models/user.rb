class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :phone, presence: true
  validates :cpf, presence: true

  has_many :memberships, dependent: :destroy
  has_many :offices, through: :memberships

  has_many :user_roles, dependent: :destroy
  has_many :roles, through: :user_roles

  has_many :provided_appointments, class_name: "Appointment", foreign_key: "provider_id", dependent: :destroy
  has_many :customer_appointments, class_name: "Appointment", foreign_key: "customer_id", dependent: :destroy


  # Automatically assign 'customer' role to new users
  after_create :assign_default_role

  private

  def assign_default_role
    customer_role = Role.find_by(name: "customer")
    self.roles << customer_role if customer_role && !self.roles.exists?(name: "customer")
  end
end
