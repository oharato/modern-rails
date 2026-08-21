class Category < ApplicationRecord
  has_many :products, dependent: :destroy

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true

  before_validation :generate_slug, if: -> { slug.blank? }

  private

  def generate_slug
    self.slug = name.to_s.parameterize
  end
end
