# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
# db/seeds.rb
Tag.destroy_all # Clean up old tags if they exist

tags = [
  "Hair Growth",
  "Moisturizing",
  "Anti-inflammatory",
  "Scalp Soothing",
  "Shine",
  "Curl Definition",
  "Preservative",
  "Emulsifier",
  "Antioxidant",
  "Humectant",
  "Emollient",
  "Surfactant"
]

tags.each do |tag_name|
  # find_or_create_by! is great because it won't create duplicates if you run the seed twice.
  Tag.find_or_create_by!(name: tag_name)
end

puts "Created #{Tag.count} tags!"