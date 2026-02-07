class CreateIngredients < ActiveRecord::Migration[8.1]
  def change
    create_table :ingredients do |t|
      t.string :name
      t.string :category
      t.text :description
      t.text :notes

      t.timestamps
    end
  end
end
