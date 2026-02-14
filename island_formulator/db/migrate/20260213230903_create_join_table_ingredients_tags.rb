class CreateJoinTableIngredientsTags < ActiveRecord::Migration[8.1]
  def change
    create_join_table :ingredients, :tags do |t|
      # t.index [:ingredient_id, :tag_id]
      # t.index [:tag_id, :ingredient_id]
    end
  end
end
