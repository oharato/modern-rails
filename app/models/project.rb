class Project < ApplicationRecord
  belongs_to :user
  has_many :tasks, dependent: :destroy

  validates :title, presence: true

  after_commit :clear_user_stats_cache

  private

  def clear_user_stats_cache
    user&.clear_stats_cache
  end
end
