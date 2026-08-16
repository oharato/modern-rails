class Task < ApplicationRecord
  belongs_to :project, optional: true
  belongs_to :user

  enum :priority, { low: 0, medium: 1, high: 2, urgent: 3 }, default: :medium

  validates :title, presence: true
  validate :project_must_belong_to_user, if: -> { project_id.present? }

  after_commit :clear_user_stats_cache

  scope :completed, -> { where(completed: true) }
  scope :pending, -> { where(completed: false) }
  scope :recent, -> { order(created_at: :desc) }

  private

  def project_must_belong_to_user
    if project.blank? || project.user_id != user_id
      errors.add(:project, "must belong to the same user")
    end
  end

  def clear_user_stats_cache
    user&.clear_stats_cache
  end
end
