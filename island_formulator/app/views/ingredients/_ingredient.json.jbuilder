json.extract! ingredient, :id, :name, :category, :description, :notes, :created_at, :updated_at
json.url ingredient_url(ingredient, format: :json)
