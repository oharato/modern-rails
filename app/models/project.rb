class Project < ApplicationRecord
  belongs_to :user
  has_many :tasks, dependent: :destroy

  validates :title, presence: true

  # Turbo Streams broadcasts
  broadcasts_refreshes
end
