
class Recipe < ApplicationRecord
  belongs_to :user
  has_one_attached :photo
  
  # A recipe has many rows in the join table
  has_many :recipe_ingredients, dependent: :destroy
  
  # A recipe has many ingredients, but it finds them by looking at the join table
  has_many :ingredients, through: :recipe_ingredients

  has_many :batches, dependent: :destroy

  
  # This is the magic line for our nested form!
  # It allows us to save ingredients at the same time we save the recipe.
  # allow_destroy: true lets us delete ingredients from a recipe.
  # reject_if: :all_blank prevents saving empty rows.
  accepts_nested_attributes_for :recipe_ingredients, allow_destroy: true, reject_if: :all_blank
  
  validates :title, presence: true
  validates :method, presence: true
  validates :product_type, presence: true
  
  # Ensure a recipe has at least one ingredient
  validate :must_have_at_least_one_ingredient
  
  private
  
  def must_have_at_least_one_ingredient
    if recipe_ingredients.reject(&:marked_for_destruction?).empty?
      errors.add(:base, "Recipe must have at least one ingredient")
    end
  end
end