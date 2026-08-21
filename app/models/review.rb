class Review < ApplicationRecord
  belongs_to :user
  belongs_to :product

  validates :rating, presence: true, inclusion: { in: 1..5 }
  validates :comment, presence: true

  scope :recent, -> { order(created_at: :desc) }
end
