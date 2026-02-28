class CreateInventoryItems < ActiveRecord::Migration[8.1]
  def change
    create_table :inventory_items do |t|
      t.references :user, null: false, foreign_key: true
      t.references :ingredient, null: false, foreign_key: true
      t.string :brand
      t.string :size
      t.string :location
      t.date :purchase_date
      t.text :notes

      t.timestamps
    end
  end
end
