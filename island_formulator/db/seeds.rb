# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
puts "Cleaning database..."
Ingredient.destroy_all

puts "Creating ingredients..."
ingredients = [
  { 
    name: "Jojoba Oil", 
    category: "Oil", 
    description: "A liquid wax produced from the seed of the Simmondsia chinensis plant.", 
    notes: "Closely resembles human sebum. Great for all hair types." 
  },
  { 
    name: "Shea Butter", 
    category: "Butter", 
    description: "A fat extracted from the nut of the African shea tree.", 
    notes: "High in vitamins A and E. Excellent for sealing in moisture." 
  },
  { 
    name: "Aloe Vera Gel", 
    category: "Humectant", 
    description: "A thick, mucilaginous liquid obtained from the leaves of the Aloe barbadensis plant.", 
    notes: "Soothing for the scalp and provides great hydration." 
  },
  { 
    name: "Castor Oil", 
    category: "Oil", 
    description: "A vegetable oil pressed from castor beans.", 
    notes: "Very thick consistency. Often used to promote hair thickness and growth." 
  },
  { 
    name: "Rosemary Essential Oil", 
    category: "Essential Oil", 
    description: "An oil extracted from the leaves of the Rosmarinus officinalis herb.", 
    notes: "Stimulates blood circulation to the scalp. Use diluted!" 
  },
  {
    name: "Argan Oil",
    category: "Oil",
    description: "Produced from the kernels of the argan tree, endemic to Morocco.",
    notes: "Often called 'liquid gold'. Great for adding shine and reducing frizz."
  },
  {
    name: "Honey",
    category: "Humectant",
    description: "A sweet, viscous food substance made by honey bees.",
    notes: "A natural humectant that attracts and retains moisture."
  }
]

ingredients.each do |attr|
  Ingredient.create!(attr)
  puts "Created #{attr[:name]}"
end

puts "Done! Created #{Ingredient.count} ingredients."