class Appointment < ApplicationRecord
  belongs_to :provider, class_name: "User", foreign_key: "provider_id"
  belongs_to :customer, class_name: "User", foreign_key: "customer_id"
  belongs_to :office

  enum :status, { pending: 0, confirmed: 1, cancelled: 2, completed: 3 }

  # Presence validations
  validates :start_datetime, :end_datetime, :book_datetime, presence: true
  validates :provider_id, :customer_id, :office_id, presence: true

  # Custom datetime validations
  validate :end_after_start
  validate :book_before_start

  private

  def end_after_start
    return if end_datetime.blank? || start_datetime.blank?

    if end_datetime <= start_datetime
      errors.add(:end_datetime, "must be after start datetime")
    end
  end

  def book_before_start
    return if book_datetime.blank? || start_datetime.blank?

    if book_datetime > start_datetime
      errors.add(:book_datetime, "must be before or at start datetime")
    end
  end
end
