# Week 3: Recipe Builder with Photos

**Time Estimate**: 4-5 hours
**Goal**: Create recipes with multiple ingredients and photos

Welcome to Week 3! This week is a major milestone. You've already built an ingredient database and added user authentication. Now, we're going to build the "heart" of the Island Formulator: the **Recipe System**.

By the end of this tutorial, you'll be able to create complex recipes that link to multiple ingredients, specify quantities for each, and even upload photos of your finished products.

---

## Part 1: Recipe Model and Associations

### Step 0: The Big Picture
Before we dive into the code, let's talk about why this week is different. In Week 1, you built a simple "CRUD" app for ingredients. In Week 2, you added users. This week, we are building a **system**. 

A system is more than just a list; it's how different pieces of data interact. A recipe isn't just a name; it's a collection of ingredients, each with its own amount, and a set of instructions. This is the most complex database structure you've built so far, but it's also the most powerful.

### Step 1: Generate Recipe and RecipeIngredient

In Rails, a "Recipe" isn't just a single table. Because a recipe has many ingredients, and an ingredient can be in many recipes, we need a **Many-to-Many** relationship. 

However, unlike the simple "Tags" from last week, we need to store extra information about the connection: the **Quantity** (e.g., "2 tbsp" or "50g"). This means we need a "Join Table with extra fields."

#### Why a Join Table?
Imagine you have a recipe for "Coconut Hair Mask." It uses "Coconut Oil." If we just linked them directly, we wouldn't know *how much* coconut oil to use. By creating a third table, `RecipeIngredient`, we can store the `recipe_id`, the `ingredient_id`, AND the `quantity`.

Run these commands in your terminal:

```bash
# Generate the Recipe model
# We include user:references because recipes belong to the person who created them
rails generate model Recipe user:references title:string product_type:string method:text

# Generate the RecipeIngredient join model
# This table connects a recipe to an ingredient and stores the quantity
rails generate model RecipeIngredient recipe:references ingredient:references quantity:string

# Run the migrations to update your database
rails db:migrate
```

### Step 2: Set Up Associations

Now we need to tell Rails how these models talk to each other. This is where we define the "logic" of our database.

#### The Recipe Model
Open `app/models/recipe.rb`. We need to tell it that it has many ingredients *through* the recipe_ingredients table.

```ruby
class Recipe < ApplicationRecord
  belongs_to :user
  
  # A recipe has many rows in the join table
  has_many :recipe_ingredients, dependent: :destroy
  
  # A recipe has many ingredients, but it finds them by looking at the join table
  has_many :ingredients, through: :recipe_ingredients
  
  # This is the magic line for our nested form!
  # It allows us to save ingredients at the same time we save the recipe.
  # allow_destroy: true lets us delete ingredients from a recipe.
  # reject_if: :all_blank prevents saving empty rows.
  accepts_nested_attributes_for :recipe_ingredients, allow_destroy: true, reject_if: :all_blank
  
  validates :title, presence: true
  validates :method, presence: true
  validates :product_type, presence: true
  
  # Ensure a recipe has at least one ingredient
  validate :must_have_at_least_one_ingredient
  
  private
  
  def must_have_at_least_one_ingredient
    if recipe_ingredients.reject(&:marked_for_destruction?).empty?
      errors.add(:base, "Recipe must have at least one ingredient")
    end
  end
end
```

#### The User Model

Don't forget to add the association to the User model as well! Open `app/models/user.rb` and add:

```ruby
class User < ApplicationRecord
  # ... existing code ...
  has_many :ingredients, dependent: :destroy
  has_many :recipes, dependent: :destroy  # Add this line
  # ...
end
```

This allows us to call `current_user.recipes` to get all recipes belonging to the logged-in user.

> **Note:** In this tutorial, we're treating ingredients as global/shared resources (available to all users). The dropdown in the recipe form will show all ingredients from the database using `Ingredient.all`.

### Step 3: Understanding Nested Attributes

**Real-World Analogy**: Think of an order form at a restaurant. The "Order" is the main paper, but it has several "Line Items" (1 Burger, 2 Fries). When you hand the paper to the waiter, you are submitting one form that creates multiple records at once.

In Rails, `accepts_nested_attributes_for` allows the `Recipe` model to save `RecipeIngredient` records at the same time the recipe itself is saved.

#### Why do we need a Join Table?
You might wonder why we don't just add an `ingredient_id` to the `Recipe` table. If we did that, a recipe could only have **one** ingredient! 

By using a join table (`RecipeIngredient`), we create a flexible link. One recipe can have many ingredients, and one ingredient can be used in many recipes. This is called a **Many-to-Many** relationship. 

The `RecipeIngredient` table is special because it also stores the **Quantity**. This is data that doesn't belong to the Ingredient (Shea Butter is always Shea Butter) or the Recipe (the recipe is the collection), but specifically to the *combination* of the two.

#### Visualizing the Relationship
Imagine three boxes:
1. **Recipe**: Title, Product Type, Method
2. **RecipeIngredient**: Recipe ID, Ingredient ID, Quantity
3. **Ingredient**: Name, Category, Description

The `RecipeIngredient` box sits in the middle, holding hands with both the Recipe and the Ingredient.

---

## Part 2: Recipe Controller and Forms

### Step 4: Create Recipe Controller

We need a controller and views to handle our recipes. Since we already created the Recipe model in Step 1, we'll use the scaffold_controller generator which creates only the controller and views (skipping the model):

```bash
rails generate scaffold_controller Recipe
```

> **Why `scaffold_controller`?** This generates a full RESTful controller with all CRUD actions (index, show, new, edit, create, update, destroy) plus the corresponding view files. Since we already created the Recipe model in Step 1, this saves us from writing all the controller actions and view templates manually.

The scaffold_controller generated a basic controller, but we need to customize it to handle nested ingredients. Replace the contents of `app/controllers/recipes_controller.rb` with:

```ruby
class RecipesController < ApplicationController
  before_action :require_authentication
  before_action :set_recipe, only: [:show, :edit, :update, :destroy]

  def index
    @recipes = current_user.recipes
  end

  def show
  end

  def new
    @recipe = current_user.recipes.build
    # Start with 5 empty ingredient slots
    5.times { @recipe.recipe_ingredients.build }
  end

  def create
    @recipe = current_user.recipes.build(recipe_params)
    if @recipe.save
      redirect_to @recipe, notice: "Recipe was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    # Ensure there's at least one empty slot for adding more
    @recipe.recipe_ingredients.build if @recipe.recipe_ingredients.empty?
  end

  def update
    if @recipe.update(recipe_params)
      redirect_to @recipe, notice: "Recipe was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @recipe.destroy
    redirect_to recipes_url, notice: "Recipe was successfully destroyed."
  end

  private

  def set_recipe
    @recipe = current_user.recipes.find(params[:id])
  end

  def recipe_params
    params.require(:recipe).permit(
      :title, 
      :product_type, 
      :method, 
      recipe_ingredients_attributes: [:id, :ingredient_id, :quantity, :_destroy]
    )
  end
end
```

**Key changes from the generated controller:**
- Added `before_action :require_authentication` to ensure only logged-in users can access recipes (this is from Week 2's authentication system)
- Using `current_user.recipes` to scope recipes to the logged-in user
- Added `5.times { @recipe.recipe_ingredients.build }` in the `new` action to prepopulate ingredient slots
- Added `recipe_ingredients_attributes` to strong parameters to handle nested form data

### Step 5: Add current_user Method to Authentication

The Rails 8 authentication system doesn't provide a `current_user` method by default. We need to add it to the Authentication concern so our controllers can access the logged-in user.

Open `app/controllers/concerns/authentication.rb` and make these changes:

```ruby
module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :require_authentication
    helper_method :authenticated?
    helper_method :current_user  # Add this line
  end
  
  # ... existing code ...

  private
    def authenticated?
      resume_session
    end

    # Add this method
    def current_user
      Current.session&.user
    end
    
    # ... rest of existing code ...
end
```

This method returns the user associated with the current session, or `nil` if no one is logged in.

### Step 6: Update Navigation

Let's add a link to the recipes section in the navigation bar so users can easily access their recipes.

Open `app/views/layouts/application.html.erb` and find the navigation section. Add the recipes link inside the authenticated block:

```erb
<%# Left side - App name and main nav %>
<div class="flex items-center gap-8">
  <%= link_to root_path, class: "text-xl font-bold text-gray-900 hover:text-blue-600 transition-colors" do %>
    Ingredient Knowledge Base
  <% end %>

  <% if authenticated? %>
    <%= link_to "My Recipes",
    recipes_path,
    class: "text-gray-600 hover:text-gray-900 transition-colors" %>
    <%= link_to "My Ingredients",
    ingredients_path,
    class: "text-gray-600 hover:text-gray-900 transition-colors" %>
  <% end %>
</div>
```

This adds a "My Recipes" link next to "My Ingredients" in the navigation bar, but only when the user is logged in.

### Step 7: Build Nested Form

This is where we use `fields_for`. This helper tells Rails "for each `recipe_ingredient` associated with this recipe, create these input fields."

Open `app/views/recipes/_form.html.erb` (create it if it doesn't exist) and add:

```erb
<%= form_with(model: recipe, class: "contents") do |form| %>
  <% if recipe.errors.any? %>
    <div
      id="error_explanation"
      class="bg-red-50 text-red-500 px-3 py-2 font-medium rounded-md mt-3"
    >
      <h2><%= pluralize(recipe.errors.count, "error") %>
        prohibited this recipe from being saved:</h2>

      <ul class="list-disc ml-6">
        <% recipe.errors.each do |error| %>
          <li><%= error.full_message %></li>
        <% end %>
      </ul>
    </div>
  <% end %>

  <div class="my-5">
    <%= form.label :title %>
    <%= form.text_field :title,
                    class: [
                      "block shadow-sm rounded-md border px-3 py-2 mt-2 w-full",
                      {
                        "border-gray-400 focus:outline-blue-600":
                          recipe.errors[:title].none?,
                        "border-red-400 focus:outline-red-600":
                          recipe.errors[:title].any?,
                      },
                    ] %>
  </div>

  <div class="my-5">
    <%= form.label :product_type, "Product Type (e.g. Hair Oil, Body Butter)" %>
    <%= form.text_field :product_type,
                    class: [
                      "block shadow-sm rounded-md border px-3 py-2 mt-2 w-full",
                      {
                        "border-gray-400 focus:outline-blue-600":
                          recipe.errors[:product_type].none?,
                        "border-red-400 focus:outline-red-600":
                          recipe.errors[:product_type].any?,
                      },
                    ] %>
  </div>

  <div class="my-5">
    <%= form.label :method %>
    <%= form.textarea :method,
                  rows: 5,
                  class: [
                    "block shadow-sm rounded-md border px-3 py-2 mt-2 w-full",
                    {
                      "border-gray-400 focus:outline-blue-600":
                        recipe.errors[:method].none?,
                      "border-red-400 focus:outline-red-600":
                        recipe.errors[:method].any?,
                    },
                  ] %>
  </div>

  <div class="my-5">
    <h3 class="font-bold mb-2">Ingredients</h3>
    <p class="text-sm text-gray-500 mb-4">Select the ingredients and specify the amount needed for this recipe.</p>

    <div class="space-y-4">
      <%= form.fields_for :recipe_ingredients do |ri_form| %>
        <div
          class="
            flex flex-col md:flex-row md:items-end space-y-2 md:space-y-0 md:space-x-4
            bg-gray-50 p-4 rounded border border-gray-200
          "
        >
          <div class="flex-1">
            <%= ri_form.label :ingredient_id, "Ingredient", class: "block text-sm font-medium text-gray-600" %>
            <%= ri_form.collection_select :ingredient_id,
                                      Ingredient.all,
                                      :id,
                                      :name,
                                      { prompt: "Select Ingredient" },
                                      { class: "block shadow-sm rounded-md border border-gray-400 px-3 py-2 mt-2 w-full focus:outline-blue-600 bg-white" } %>
          </div>

          <div class="w-full md:w-48">
            <%= ri_form.label :quantity, "Amount", class: "block text-sm font-medium text-gray-600" %>
            <%= ri_form.text_field :quantity,
                               placeholder: "e.g. 50g or 2 tbsp",
                               class: "block shadow-sm rounded-md border border-gray-400 px-3 py-2 mt-2 w-full focus:outline-blue-600" %>
          </div>

          <% if ri_form.object.persisted? %>
            <div class="flex items-center pb-2">
              <%= ri_form.check_box :_destroy,
                                class: "h-4 w-4 text-red-600 border-gray-300 rounded" %>
              <%= ri_form.label :_destroy,
                            "Remove",
                            class: "ml-2 text-red-600 text-sm font-medium" %>
            </div>
          <% end %>
        </div>
      <% end %>
    </div>
  </div>

  <div class="inline">
    <%= form.submit class:
                  "w-full sm:w-auto rounded-md px-3.5 py-2.5 bg-blue-600 hover:bg-blue-500 text-white inline-block font-medium cursor-pointer" %>
  </div>
<% end %>
```

### Step 8: Understanding Strong Parameters

Look closely at the `recipe_params` in the controller. We added `recipe_ingredients_attributes`. 

```ruby
recipe_ingredients_attributes: [:id, :ingredient_id, :quantity, :_destroy]
```

- `:id`: This is crucial! When you edit a recipe, Rails uses this ID to know which existing `RecipeIngredient` record you are changing. Without it, Rails might try to create a brand new record every time you save.
- `:ingredient_id` and `:quantity`: These are the actual values we want to save.
- `:_destroy`: This is a special virtual attribute. If it's set to `true` (by checking the "Remove" box), Rails will delete that specific `RecipeIngredient` record when the recipe is saved.

#### What does the data look like?
When you submit the form, Rails receives a "hash" of data that looks something like this:

```ruby
{
  "recipe" => {
    "title" => "My Hair Oil",
    "recipe_ingredients_attributes" => {
      "0" => { "ingredient_id" => "1", "quantity" => "100ml" },
      "1" => { "ingredient_id" => "5", "quantity" => "10 drops" }
    }
  }
}
```

Rails sees the `_attributes` suffix and knows to pass that data to the `RecipeIngredient` model.

---

## Part 3: Photo Uploads

### Step 9: Install ActiveStorage

In a formulation app, photos aren't just for decoration. They are part of your documentation. A photo of a finished batch helps you remember the texture, color, and consistency. Did the oil separate? Was the butter smooth or grainy? A picture is worth a thousand notes.

ActiveStorage is Rails' built-in way to handle file uploads. It handles the "plumbing" of connecting files to your database records. It can store files on your computer (for development) or on services like Amazon S3 or Google Cloud (for production).

Run this command:

```bash
rails active_storage:install
rails db:migrate
```

This creates two tables:
1. `active_storage_blobs`: Stores metadata about the file (filename, size, content type).
2. `active_storage_attachments`: The "glue" that links a blob to your model (e.g., linking a photo blob to Recipe #5).

### Step 10: Add Photo Attachments

We want both Recipes and Ingredients to have photos. This makes the app much more visual and professional.

Update `app/models/recipe.rb`:
```ruby
class Recipe < ApplicationRecord
  # ...
  has_one_attached :photo
end
```

Update `app/models/ingredient.rb`:
```ruby
class Ingredient < ApplicationRecord
  # ...
  has_one_attached :photo
end
```

### Step 11: Update Forms for Photos

#### Recipe Form

Add the file input to your Recipe form (`app/views/recipes/_form.html.erb`). I recommend putting it near the top so it's easy to find.

```erb
<div class="bg-white shadow p-6 rounded-lg">
  <%= form.label :photo, "Recipe Photo", class: "block font-bold text-gray-700 mb-2" %>
  <div class="flex items-center justify-center w-full">
    <label class="flex flex-col items-center justify-center w-full h-32 border-2 border-gray-300 border-dashed rounded-lg cursor-pointer bg-gray-50 hover:bg-gray-100">
      <div class="flex flex-col items-center justify-center pt-5 pb-6">
        <svg class="w-8 h-8 mb-4 text-gray-500" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 20 16">
          <path stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 13h3a3 3 0 0 0 0-6h-.025A5.56 5.56 0 0 0 16 6.5 5.5 5.5 0 0 0 5.207 5.021C5.137 5.017 5.071 5 5 5a4 4 0 0 0 0 8h2.167M10 15V6m0 0L8 8m2-2 2 2"/>
        </svg>
        <p class="mb-2 text-sm text-gray-500"><span class="font-semibold">Click to upload</span> or drag and drop</p>
        <p class="text-xs text-gray-500">PNG, JPG or GIF</p>
      </div>
      <%= form.file_field :photo, accept: "image/*", class: "hidden" %>
    </label>
  </div>
  <% if recipe.photo.attached? %>
    <p class="mt-2 text-sm text-green-600">✓ Current photo: <%= recipe.photo.filename %></p>
  <% end %>
</div>
```

**CRITICAL**: Don't forget to update your `recipe_params` in `recipes_controller.rb` to permit the `:photo` field!

```ruby
def recipe_params
  params.require(:recipe).permit(
    :title, 
    :product_type, 
    :method, 
    :photo,
    recipe_ingredients_attributes: [:id, :ingredient_id, :quantity, :_destroy]
  )
end
```

#### Ingredient Form

Update your Ingredient form (`app/views/ingredients/_form.html.erb`) to include photo upload:

```erb
<div class="bg-white shadow p-6 rounded-lg">
  <%= form.label :photo, "Ingredient Photo", class: "block font-bold text-gray-700 mb-2" %>
  <div class="flex items-center justify-center w-full">
    <label class="flex flex-col items-center justify-center w-full h-32 border-2 border-gray-300 border-dashed rounded-lg cursor-pointer bg-gray-50 hover:bg-gray-100">
      <div class="flex flex-col items-center justify-center pt-5 pb-6">
        <svg class="w-8 h-8 mb-4 text-gray-500" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 20 16">
          <path stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 13h3a3 3 0 0 0 0-6h-.025A5.56 5.56 0 0 0 16 6.5 5.5 5.5 0 0 0 5.207 5.021C5.137 5.017 5.071 5 5 5a4 4 0 0 0 0 8h2.167M10 15V6m0 0L8 8m2-2 2 2"/>
        </svg>
        <p class="mb-2 text-sm text-gray-500"><span class="font-semibold">Click to upload</span> or drag and drop</p>
        <p class="text-xs text-gray-500">PNG, JPG or GIF</p>
      </div>
      <%= form.file_field :photo, accept: "image/*", class: "hidden" %>
    </label>
  </div>
  <% if ingredient.photo.attached? %>
    <p class="mt-2 text-sm text-green-600">✓ Current photo: <%= ingredient.photo.filename %></p>
  <% end %>
</div>
```

And update the `ingredient_params` in your IngredientsController:

```ruby
def ingredient_params
  params.require(:ingredient).permit(:name, :category, :description, :photo)
end
```

### Step 12: Display Photos and Build Index View

In `app/views/recipes/show.html.erb`, we want to show the photo prominently. We'll use Tailwind's grid system to create a layout where the photo and ingredients are on one side, and the method is on the other.

#### Understanding the Layout
We are using a `grid-cols-1 md:grid-cols-3` layout. This means:
- **Mobile First**: On small screens (like a phone), everything will be in one column (stacked). This makes it easy to read while you're in the kitchen.
- **Desktop Power**: On desktop (medium screens and up), the page will split into 3 columns.
- **The Sidebar**: The photo and the ingredient list will take up 1 column (`md:col-span-1`). This acts like a sidebar.
- **The Main Content**: The method/instructions will take up 2 columns (`md:col-span-2`). This gives you plenty of space for long, detailed preparation steps.

This creates a balanced, professional-looking recipe card that works on any device.

```erb
<div class="max-w-4xl mx-auto p-6">
  <div class="flex justify-between items-start mb-6">
    <div>
      <h1 class="text-4xl font-bold text-gray-900"><%= @recipe.title %></h1>
      <span class="inline-block bg-green-100 text-green-800 text-xs px-2 py-1 rounded-full mt-2 font-semibold uppercase tracking-wide">
        <%= @recipe.product_type %>
      </span>
    </div>
    <div class="space-x-2">
      <%= link_to "Edit", edit_recipe_path(@recipe), class: "bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700" %>
      <%= link_to "Back", recipes_path, class: "text-gray-600 hover:underline" %>
    </div>
  </div>
  
  <div class="grid grid-cols-1 md:grid-cols-3 gap-8">
    <div class="md:col-span-1">
      <% if @recipe.photo.attached? %>
        <%= image_tag @recipe.photo, class: "w-full h-auto object-cover rounded-xl shadow-lg border-4 border-white" %>
      <% else %>
        <div class="w-full h-64 bg-gray-200 rounded-xl flex items-center justify-center text-gray-400 italic">
          No photo uploaded
        </div>
      <% end %>
      
      <div class="mt-8 bg-white p-6 rounded-xl shadow-sm border border-gray-100">
        <h2 class="text-xl font-bold mb-4 text-gray-800 border-b pb-2">Ingredients</h2>
        <ul class="space-y-3">
          <% @recipe.recipe_ingredients.each do |ri| %>
            <li class="flex justify-between items-center">
              <span class="font-medium text-gray-700"><%= ri.ingredient.name %></span>
              <span class="text-gray-500 bg-gray-100 px-2 py-1 rounded text-sm"><%= ri.quantity %></span>
            </li>
          <% end %>
        </ul>
      </div>
    </div>

    <div class="md:col-span-2">
      <div class="bg-white p-8 rounded-xl shadow-sm border border-gray-100 h-full">
        <h2 class="text-2xl font-bold mb-4 text-gray-800">Method</h2>
        <div class="prose prose-green max-w-none text-gray-700 leading-relaxed">
          <%= simple_format @recipe.method %>
        </div>
      </div>
    </div>
  </div>
</div>
```

#### Understanding `simple_format`

The `simple_format` helper converts plain text into HTML by:
- Wrapping paragraphs in `<p>` tags
- Converting line breaks into `<br>` tags
- Maintaining basic formatting from your text

This means when users type instructions with line breaks like:
```
Step 1: Mix oils
Step 2: Heat gently
Step 3: Add butter
```

It will display properly formatted with spacing, instead of running together as one long line. Without it, all your recipe instructions would appear as a single paragraph!

#### The Recipe Index View

The scaffold_controller already created `app/views/recipes/index.html.erb`, but it has the default scaffold styling. Let's update it to match our app's design and display photos:

```erb
<div class="max-w-6xl mx-auto p-6">
  <div class="flex justify-between items-center mb-6">
    <h1 class="text-3xl font-bold text-gray-900">My Recipes</h1>
    <%= link_to "New Recipe", new_recipe_path, class: "bg-green-600 text-white px-6 py-2 rounded-lg font-bold hover:bg-green-700" %>
  </div>

  <% if @recipes.empty? %>
    <div class="text-center py-12 bg-white rounded-lg shadow">
      <p class="text-gray-500 mb-4">You haven't created any recipes yet.</p>
      <%= link_to "Create Your First Recipe", new_recipe_path, class: "text-green-600 font-semibold hover:underline" %>
    </div>
  <% else %>
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      <% @recipes.each do |recipe| %>
        <div class="bg-white rounded-lg shadow hover:shadow-lg transition-shadow">
          <% if recipe.photo.attached? %>
            <%= image_tag recipe.photo, class: "w-full h-48 object-cover rounded-t-lg" %>
          <% else %>
            <div class="w-full h-48 bg-gray-200 rounded-t-lg flex items-center justify-center text-gray-400">
              No photo
            </div>
          <% end %>
          
          <div class="p-4">
            <h2 class="text-xl font-bold mb-2"><%= link_to recipe.title, recipe, class: "text-gray-900 hover:text-green-600" %></h2>
            <span class="inline-block bg-green-100 text-green-800 text-xs px-2 py-1 rounded-full font-semibold uppercase tracking-wide">
              <%= recipe.product_type %>
            </span>
            <p class="text-gray-500 text-sm mt-2"><%= pluralize(recipe.ingredients.count, 'ingredient') %></p>
          </div>
        </div>
      <% end %>
    </div>
  <% end %>
</div>
```

**Note**: This assumes you have `has_many :ingredients, through: :recipe_ingredients` in your Recipe model and that users have many ingredients (from Week 2). If `current_user.ingredients` doesn't work yet, make sure you added `has_many :ingredients` to your User model in Week 2.

#### Displaying Photos on the Ingredients Page
Don't forget that we also added photos to the `Ingredient` model! Let's update the ingredient show page (`app/views/ingredients/show.html.erb`) to display them:

```erb
<div class="max-w-2xl mx-auto bg-white shadow rounded-lg overflow-hidden">
  <% if @ingredient.photo.attached? %>
    <%= image_tag @ingredient.photo, class: "w-full h-64 object-cover" %>
  <% end %>
  
  <div class="p-6">
    <h1 class="text-3xl font-bold mb-2"><%= @ingredient.name %></h1>
    <p class="text-gray-600 mb-4"><%= @ingredient.category %></p>
    
    <div class="mb-6">
      <h2 class="font-bold text-gray-700 uppercase text-xs tracking-wider mb-2">Description</h2>
      <p class="text-gray-800"><%= @ingredient.description %></p>
    </div>

    <div class="flex space-x-2">
      <%= link_to 'Edit', edit_ingredient_path(@ingredient), class: "bg-blue-500 text-white px-4 py-2 rounded" %>
      <%= link_to 'Back', ingredients_path, class: "text-gray-500 py-2" %>
    </div>
  </div>
</div>
```

---

## Troubleshooting Common Issues

### 1. "Missing host to link to!" Error
If you see an error about "host" when trying to view an image, it's because Rails needs to know your website's URL to generate the image link. In development, add this to `config/environments/development.rb`:

```ruby
config.action_mailer.default_url_options = { host: 'localhost', port: 3000 }
```

### 2. Ingredients not saving
If your recipe saves but the ingredients are missing:
- Check your `recipe_params` in the controller. Did you include `recipe_ingredients_attributes`?
- Check your model. Did you include `accepts_nested_attributes_for`?
- Check your form. Are you using `fields_for :recipe_ingredients`?

### 3. "Unpermitted parameters" in the logs
If you see this in your terminal, it means you forgot to add a field to your `recipe_params`. Rails blocks any data that isn't explicitly allowed for security reasons.

---

## Testing Complete Workflow

1. **Check Ingredients**: Go to `/ingredients` and make sure you have at least 3 ingredients.
2. **Create Recipe**: Go to `/recipes/new`.
3. **Fill Details**: Fill in the title and method.
4. **Add Ingredients**: Select ingredients from the dropdowns and type in quantities.
5. **Upload Photo**: Choose a photo from your computer.
6. **Save**: Click "Create Recipe".
7. **Verify**: Check that the show page displays the photo and the list of ingredients correctly.
8. **Edit**: Try editing the recipe, changing a quantity, and removing an ingredient.

---

## Git Commits

It's time to save your progress! Remember to commit often.

```bash
git add .
git commit -m "feat(recipes): add recipe model with nested ingredient associations"
git commit -m "feat(uploads): add ActiveStorage for recipe and ingredient photos"
```

---

## Cut Here If Behind

If you are running out of time this week, don't panic! Here is what you can skip:

1. **Skip the Photo Uploads**. Focus entirely on getting the Recipe and RecipeIngredient associations working. This is the most important technical concept of the week.
2. **Skip the fancy Tailwind styling**. Just get the fields on the page. You can make it pretty later.
3. **Hardcode the number of ingredients**. Don't worry about dynamic "Add Row" buttons yet; just build the form with 5 static slots as shown in the controller.

---

## Next Week Preview

Next week, we'll build the **Inventory Tracker**. You'll learn how to track the actual bottles and jars you buy (Inventory Items) and link them to your master Ingredient list. We'll also add **Batch Logging** so you can record every time you actually make one of your recipes!

Great job today! You've built a complex, real-world data relationship and added file handling to your app. You're building a real tool that people can use! 🚀
