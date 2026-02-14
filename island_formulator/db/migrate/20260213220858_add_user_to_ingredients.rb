class AddUserToIngredients < ActiveRecord::Migration[8.1]
  def change
    add_reference :ingredients, :user, null: false, foreign_key: true
  end
end
