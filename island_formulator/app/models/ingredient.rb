class Ingredient < ApplicationRecord 
  belongs_to :user 

  has_and_belongs_to_many :tags, join_table: :ingredients_tags 
  has_one_attached :photo

  has_many :recipe_ingredients, dependent: :destroy
  has_many :recipes, through: :recipe_ingredients

  has_many :inventory_items, dependent: :destroy   

  validates :name, presence: true 
  validates :category, presence: true 
  validates :user, presence: true 
end
