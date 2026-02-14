class Ingredient < ApplicationRecord 
    belongs_to :user 
    has_and_belongs_to_many :tags, join_table: :ingredients_tags 
    
    validates :name, presence: true 
    validates :category, presence: true 
    validates :user, presence: true 
end