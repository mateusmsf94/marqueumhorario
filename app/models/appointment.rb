class Appointment < ApplicationRecord
  belongs_to :provider, class_name: "User", foreign_key: "provider_id"
  belongs_to :customer, class_name: "User", foreign_key: "customer_id"
  belongs_to :office

  enum :status, { pending: 0, confirmed: 1, cancelled: 2, completed: 3, no_show: 4 }

  # Presence validations
  validates :start_datetime, :end_datetime, :book_datetime, presence: true
  validates :provider_id, :customer_id, :office_id, presence: true

  # Custom datetime validations
  validate :end_after_start
  validate :book_before_start
  validate :start_in_future, on: :create
  validate :prevent_double_booking

  scope :upcoming, -> { where("start_datetime >= ?", Time.current).order(:start_datetime) }
  scope :past, -> { where("start_datetime < ?", Time.current).order(start_datetime: :desc) }
  scope :by_date, ->(date) { where(start_datetime: date.beginning_of_day..date.end_of_day).order(:start_datetime) }
  scope :for_user, ->(user) { where("provider_id = :user_id OR customer_id = :user_id", user_id: user.is_a?(User) ? user.id : user) }
  scope :for_office, ->(office) { where(office_id: office.is_a?(Office) ? office.id : office) }

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

  def start_in_future
    return if start_datetime.blank?

    if start_datetime < Time.current
      errors.add(:start_datetime, "must be in the future")
    end
  end

  def prevent_double_booking
    return if start_datetime.blank? || end_datetime.blank? || provider_id.blank? || office_id.blank? || customer_id.blank?

    overlapping_scope = self.class
      .where.not(id: id)
      .where("start_datetime < :end_time AND end_datetime > :start_time", end_time: end_datetime, start_time: start_datetime)
      .where.not(status: self.class.statuses[:cancelled])

    if overlapping_scope.where(provider_id: provider_id).exists?
      errors.add(:base, "provider is already booked during this time")
    end

    if overlapping_scope.where(customer_id: customer_id).exists?
      errors.add(:base, "customer is already booked during this time")
    end

    if overlapping_scope.where(office_id: office_id).exists?
      errors.add(:base, "office is already booked during this time")
    end
  end
end
