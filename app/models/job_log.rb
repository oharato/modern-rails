class JobLog < ApplicationRecord
  validates :job_type, presence: true
  validates :status, presence: true

  scope :recent, -> { order(created_at: :desc).limit(50) }
end
