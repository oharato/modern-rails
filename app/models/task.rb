class Task < ApplicationRecord
  belongs_to :project, optional: true
  belongs_to :user

  enum :priority, { low: 0, medium: 1, high: 2, urgent: 3 }, default: :medium

  validates :title, presence: true

  scope :completed, -> { where(completed: true) }
  scope :pending, -> { where(completed: false) }
  scope :recent, -> { order(created_at: :desc) }

  # Rails 8 / Turbo 8 Morphing & Refresh support
  broadcasts_refreshes
end
