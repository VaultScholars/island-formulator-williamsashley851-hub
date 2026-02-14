class IngredientTag < ApplicationRecord
  # This is the bridge. It belongs to both sides.
  # It's like a link in a chain connecting an Ingredient to a Tag.
  belongs_to :ingredient
  belongs_to :tag
end