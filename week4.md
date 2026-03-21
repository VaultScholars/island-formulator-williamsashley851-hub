# Week 4: Inventory Tracking and Batch History

**Time Estimate**: 4-5 hours
**Goal**: Track purchases and log when you make batches

Welcome to Week 4! This week, we're moving from **Template Data** (the patterns/templates for your ingredients and recipes) to **Transactional Data** (the actual things you buy and the batches you make).

By the end of this week, you'll have a working dashboard that summarizes your entire formulation business (or hobby!) in one place.

---

## Part 0: Prerequisites Check (Optional)

### Step 0: Fix Ingredients User Association (If Needed)

> **Note**: This step is **optional**. Some students may have already fixed this in Week 2. 
> 
> **Skip this if**: Your ingredients are already scoped to the current user. **Check this**: Open `app/controllers/ingredients_controller.rb` and look at the `new` action. If you see `current_user.ingredients.build`, you're already done!
> 
> **Do this if**: Your `new` action has `Ingredient.new` (without `current_user`), which means ingredients are global/shared and all users see all ingredients.

If you want ingredients to be private to each user (like recipes are), follow these steps:

**1. Update the Ingredient model** (`app/models/ingredient.rb`):

```ruby
class Ingredient < ApplicationRecord
  belongs_to :user  # Add this line
  has_many :recipe_ingredients, dependent: :destroy
  has_many :recipes, through: :recipe_ingredients
  has_many :inventory_items, dependent: :destroy
  
  # ... rest of your code ...
end
```

**2. Update the IngredientsController** (`app/controllers/ingredients_controller.rb`):

Make these specific changes to your existing controller:

```ruby
class IngredientsController < ApplicationController
  before_action :require_authentication  # Add this line at the top
  before_action :set_ingredient, only: %i[ show edit update destroy ]

  def index
    @ingredients = current_user.ingredients  # Was: Ingredient.all
  end

  def show
  end

  def new
    @ingredient = current_user.ingredients.build  # Was: Ingredient.new
  end

  def create
    @ingredient = current_user.ingredients.build(ingredient_params)  # Was: Ingredient.new(ingredient_params)
    
    if @ingredient.save
      redirect_to @ingredient, notice: "Ingredient was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # Keep your existing edit, update, and destroy actions unchanged

  private

  def set_ingredient
    @ingredient = current_user.ingredients.find(params[:id])  # Was: Ingredient.find(params[:id])
  end

  def ingredient_params
    params.require(:ingredient).permit(:name, :category, :description, :notes, :photo, tag_ids: [])
  end
end
```

**Summary of changes:**
1. **Add authentication**: Insert `before_action :require_authentication` at the top
2. **Scope the index**: Change `Ingredient.all` → `current_user.ingredients`
3. **Build through user in new**: Change `Ingredient.new` → `current_user.ingredients.build`
4. **Build through user in create**: Change `Ingredient.new(ingredient_params)` → `current_user.ingredients.build(ingredient_params)`
5. **Scope the finder**: Change `Ingredient.find(params[:id])` → `current_user.ingredients.find(params[:id])`

**3. Associate existing ingredients with a user**

If you already have ingredients in your database without a user_id, you need to assign them to a user or the app will crash when trying to view them.

Open your terminal and run these commands one at a time:

```bash
rails console
```

Then in the console, run:

```ruby
user = User.first
```

```ruby
Ingredient.where(user_id: nil).update_all(user_id: user.id)
```

```ruby
Ingredient.where(user_id: nil).count
```

Should return `0`. Then exit:

```ruby
exit
```

> **Note**: After running these commands, restart your Rails server with `Ctrl+C` then `rails server` to ensure the changes take effect.

---

## Part 1: Inventory Items

### Step 1: Understanding Template vs Instance Data

Before we write any code, we need to understand a critical concept in database design: the difference between **Template Data** and **Instance Data**.

Think about a recipe for Chocolate Chip Cookies.
- **Ingredient (Template Data)**: "Chocolate Chips". This is the general concept. It has a name and maybe a category.
- **InventoryItem (Instance Data)**: The actual 12oz bag of "Ghirardelli Semi-Sweet Chocolate Chips" you bought at the supermarket yesterday for $5.99.

In our app:
- **Ingredient** is the "template" (e.g., Shea Butter).
- **InventoryItem** is the specific bag or bottle sitting on your shelf.

**Why separate them?** Because you might buy Shea Butter five different times from three different brands. You don't want to create five "Shea Butter" ingredients; you want one "Shea Butter" ingredient and five "Inventory Items" linked to it.

### Step 2: Generate InventoryItem Model

We need a model to track these specific purchases. We'll include fields for the brand, size, location, and the date you bought it.

Run these commands in your terminal (one at a time):

```bash
rails generate model InventoryItem user:references ingredient:references brand:string size:string location:string purchase_date:date notes:text
```

```bash
rails db:migrate
```

#### Update Associations

Now, let's tell Rails how these models relate to each other.

In `app/models/user.rb`:
```ruby
has_many :inventory_items, dependent: :destroy
```

In `app/models/ingredient.rb`:
```ruby
has_many :inventory_items, dependent: :destroy
```

In `app/models/inventory_item.rb`:
```ruby
class InventoryItem < ApplicationRecord
  belongs_to :user
  belongs_to :ingredient
  has_one_attached :photo # Optional: take a photo of the receipt or bottle!

  validates :ingredient_id, presence: true
  validates :purchase_date, presence: true
end
```

### Step 3: Create Inventory CRUD

We need a way to add and view these items. Since we already created the InventoryItem model, we'll use scaffold_controller to generate the controller and views:

```bash
rails generate scaffold_controller InventoryItem
```

> **Why `scaffold_controller`?** This generates a full RESTful controller with all CRUD actions plus the corresponding view files. Since we already created the model, this saves us from writing everything from scratch.

Now customize the generated controller in `app/controllers/inventory_items_controller.rb`

Update `app/controllers/inventory_items_controller.rb`:

```ruby
class InventoryItemsController < ApplicationController
  before_action :require_authentication  # Add this line
  before_action :set_inventory_item, only: %i[ show edit update destroy ]

  def index
    # We use .includes(:ingredient) to avoid "N+1" queries.
    # This is a performance optimization that loads all ingredients in one go!
    @inventory_items = current_user.inventory_items.includes(:ingredient).order(purchase_date: :desc)
  end

  def show
  end

  def new
    @inventory_item = current_user.inventory_items.build
  end

  def edit
  end

  def create
    @inventory_item = current_user.inventory_items.build(inventory_item_params)

    if @inventory_item.save
      redirect_to inventory_items_path, notice: "Inventory item was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @inventory_item.update(inventory_item_params)
      redirect_to inventory_items_path, notice: "Inventory item was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @inventory_item.destroy
    redirect_to inventory_items_path, notice: "Inventory item was successfully removed."
  end

  private

  def set_inventory_item
    @inventory_item = current_user.inventory_items.find(params[:id])
  end

  def inventory_item_params
    params.require(:inventory_item).permit(:ingredient_id, :brand, :size, :location, :purchase_date, :notes, :photo)
  end
end
```

#### The Views

In `app/views/inventory_items/index.html.erb`:

```erb
<div class="w-full">
  <% if notice.present? %>
    <p class="py-2 px-3 bg-green-50 text-green-500 font-medium rounded-lg inline-block mb-5" id="notice"><%= notice %></p>
  <% end %>

  <div class="flex justify-between items-center">
    <h1 class="font-bold text-4xl">Inventory</h1>
    <%= link_to "New Inventory Item", new_inventory_item_path, class: "rounded-lg py-3 px-5 bg-blue-600 text-white block font-medium" %>
  </div>

  <div id="inventory_items" class="min-w-full mt-8">
    <div class="overflow-x-auto shadow rounded-lg">
      <table class="min-w-full bg-white">
        <thead class="bg-gray-50 border-b">
          <tr>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Ingredient</th>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Brand</th>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Size</th>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Location</th>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Purchased</th>
            <th class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-gray-200">
          <% @inventory_items.each do |item| %>
            <tr>
              <td class="px-6 py-4 whitespace-nowrap font-medium text-gray-900"><%= item.ingredient.name %></td>
              <td class="px-6 py-4 whitespace-nowrap text-gray-500"><%= item.brand %></td>
              <td class="px-6 py-4 whitespace-nowrap text-gray-500"><%= item.size %></td>
              <td class="px-6 py-4 whitespace-nowrap text-gray-500"><%= item.location %></td>
              <td class="px-6 py-4 whitespace-nowrap text-gray-500"><%= item.purchase_date.strftime("%b %d, %Y") %></td>
              <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                <%= link_to "Show", item, class: "text-blue-600 hover:text-blue-900 mr-3" %>
                <%= link_to "Edit", edit_inventory_item_path(item), class: "text-gray-600 hover:text-gray-900" %>
              </td>
            </tr>
          <% end %>
        </tbody>
      </table>
    </div>
  </div>
</div>
```

In `app/views/inventory_items/show.html.erb`:

```erb
<div class="mx-auto md:w-2/3 w-full flex flex-col items-center">
  <div class="bg-white shadow rounded-lg p-8 w-full">
    <div class="flex justify-between items-start mb-6">
      <div>
        <h1 class="font-bold text-3xl text-gray-900"><%= @inventory_item.ingredient.name %></h1>
        <p class="text-gray-500"><%= @inventory_item.brand %></p>
      </div>
      <span class="bg-blue-100 text-blue-800 text-xs font-semibold px-2.5 py-0.5 rounded uppercase">
        <%= @inventory_item.ingredient.category %>
      </span>
    </div>

    <% if @inventory_item.photo.attached? %>
      <div class="mb-6">
        <%= image_tag @inventory_item.photo, class: "w-full h-64 object-cover rounded-lg shadow-sm" %>
      </div>
    <% end %>

    <div class="grid grid-cols-2 gap-6 mb-8">
      <div>
        <p class="text-sm font-bold text-gray-500 uppercase">Size</p>
        <p class="text-lg"><%= @inventory_item.size.presence || "Not specified" %></p>
      </div>
      <div>
        <p class="text-sm font-bold text-gray-500 uppercase">Location</p>
        <p class="text-lg"><%= @inventory_item.location.presence || "Not specified" %></p>
      </div>
      <div>
        <p class="text-sm font-bold text-gray-500 uppercase">Purchase Date</p>
        <p class="text-lg"><%= @inventory_item.purchase_date.strftime("%B %d, %Y") %></p>
      </div>
    </div>

    <% if @inventory_item.notes.present? %>
      <div class="mb-8">
        <p class="text-sm font-bold text-gray-500 uppercase mb-2">Notes</p>
        <div class="bg-gray-50 p-4 rounded-lg text-gray-700">
          <%= simple_format @inventory_item.notes %>
        </div>
      </div>
    <% end %>

    <div class="flex gap-2">
      <%= link_to "Edit this item", edit_inventory_item_path(@inventory_item), class: "rounded-lg py-3 px-5 bg-gray-100 font-medium" %>
      <%= button_to "Remove from inventory", @inventory_item, method: :delete, class: "rounded-lg py-3 px-5 bg-red-50 text-red-600 font-medium", data: { confirm: "Are you sure?" } %>
      <%= link_to "Back to inventory", inventory_items_path, class: "ml-auto rounded-lg py-3 px-5 bg-blue-600 text-white font-medium" %>
    </div>
  </div>
</div>
```

#### The Form

Now let's create the form for adding inventory items. This form needs a dropdown to select which ingredient you're buying (from all available ingredients), plus fields for brand, size, location, and purchase date. We'll also add a photo upload so you can take a picture of the receipt or the bottle!

In `app/views/inventory_items/_form.html.erb`:

```erb
<%= form_with(model: inventory_item, class: "contents") do |form| %>
  <% if inventory_item.errors.any? %>
    <div id="error_explanation" class="bg-red-50 text-red-500 px-3 py-2 font-medium rounded-lg mt-3">
      <h2><%= pluralize(inventory_item.errors.count, "error") %> prohibited this item from being saved:</h2>
      <ul>
        <% inventory_item.errors.each do |error| %>
          <li><%= error.full_message %></li>
        <% end %>
      </ul>
    </div>
  <% end %>

  <div class="my-5">
    <%= form.label :ingredient_id, "Which Ingredient?" %>
    <%= form.collection_select :ingredient_id, Ingredient.all, :id, :name, 
        { prompt: "Select an ingredient" }, 
        { class: "block shadow rounded-md border border-gray-200 outline-none px-3 py-2 mt-2 w-full" } %>
  </div>

  <div class="my-5">
    <%= form.label :brand %>
    <%= form.text_field :brand, class: "block shadow rounded-md border border-gray-200 outline-none px-3 py-2 mt-2 w-full" %>
  </div>

  <div class="my-5">
    <%= form.label :size, "Size (e.g. 500ml, 16oz)" %>
    <%= form.text_field :size, class: "block shadow rounded-md border border-gray-200 outline-none px-3 py-2 mt-2 w-full" %>
  </div>

  <div class="my-5">
    <%= form.label :location, "Where is it stored?" %>
    <%= form.text_field :location, class: "block shadow rounded-md border border-gray-200 outline-none px-3 py-2 mt-2 w-full" %>
  </div>

  <div class="my-5">
    <%= form.label :purchase_date %>
    <%= form.date_field :purchase_date, class: "block shadow rounded-md border border-gray-200 outline-none px-3 py-2 mt-2 w-full" %>
  </div>

  <div class="my-5">
    <%= form.label :notes %>
    <%= form.text_area :notes, rows: 4, class: "block shadow rounded-md border border-gray-200 outline-none px-3 py-2 mt-2 w-full" %>
  </div>

  <div class="bg-white shadow p-6 rounded-lg mb-5">
    <%= form.label :photo, "Photo (receipt or bottle)", class: "block font-bold text-gray-700 mb-2" %>
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
    <% if inventory_item.photo.attached? %>
      <p class="mt-2 text-sm text-green-600">✓ Current photo: <%= inventory_item.photo.filename %></p>
    <% end %>
  </div>

  <div class="inline">
    <%= form.submit class: "rounded-lg py-3 px-5 bg-blue-600 text-white inline-block font-medium cursor-pointer" %>
  </div>
<% end %>
```

#### The New View

The scaffold_controller created `app/views/inventory_items/new.html.erb`, but we should update it to match our styling. Update it to:

```erb
<div class="mx-auto md:w-2/3 w-full">
  <h1 class="font-bold text-4xl">New Inventory Item</h1>

  <%= render "form", inventory_item: @inventory_item %>

  <%= link_to "Back to inventory", inventory_items_path, class: "ml-2 rounded-lg py-3 px-5 bg-gray-100 inline-block font-medium" %>
</div>
```

#### The Edit View

Create `app/views/inventory_items/edit.html.erb`:

```erb
<div class="mx-auto md:w-2/3 w-full">
  <h1 class="font-bold text-4xl">Edit Inventory Item</h1>

  <%= render "form", inventory_item: @inventory_item %>

  <%= link_to "Show this item", @inventory_item, class: "ml-2 rounded-lg py-3 px-5 bg-gray-100 inline-block font-medium" %>
  <%= link_to "Back to inventory", inventory_items_path, class: "ml-2 rounded-lg py-3 px-5 bg-gray-100 inline-block font-medium" %>
</div>
```

---

## Part 2: Batch Logging

### Step 4: Generate Batch Model

A **Batch** is a record of you actually making a recipe. It's your production log.

Run these commands in your terminal (one at a time):

```bash
rails generate model Batch user:references recipe:references made_on:date notes:text
```

```bash
rails db:migrate
```

#### Update Associations

In `app/models/user.rb`:
```ruby
has_many :batches, dependent: :destroy
```

In `app/models/recipe.rb`:
```ruby
has_many :batches, dependent: :destroy
```

In `app/models/batch.rb`:
```ruby
class Batch < ApplicationRecord
  belongs_to :user
  belongs_to :recipe

  validates :made_on, presence: true
end
```

### Step 5: Create Batch Controller

Generate the controller and views for batches:

```bash
rails generate scaffold_controller Batch
```

Now customize the generated controller in `app/controllers/batches_controller.rb`:

```ruby
class BatchesController < ApplicationController
  before_action :require_authentication  # Add this line
  
  def index
    @batches = current_user.batches.includes(:recipe).order(made_on: :desc)
  end

  def show
    @batch = current_user.batches.find(params[:id])
  end

  def new
    @batch = current_user.batches.build(
      recipe_id: params[:recipe_id],
      made_on: Date.today
    )
  end

  def create
    @batch = current_user.batches.build(batch_params)

    if @batch.save
      redirect_to batches_path, notice: "Batch was successfully logged."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def batch_params
    params.require(:batch).permit(:recipe_id, :made_on, :notes)
  end
end
```

#### The Views

In `app/views/batches/index.html.erb`:

```erb
<div class="w-full">
  <% if notice.present? %>
    <p class="py-2 px-3 bg-green-50 text-green-500 font-medium rounded-lg inline-block mb-5" id="notice"><%= notice %></p>
  <% end %>

  <div class="flex justify-between items-center">
    <h1 class="font-bold text-4xl">Batch History</h1>
    <%= link_to "Log New Batch", new_batch_path, class: "rounded-lg py-3 px-5 bg-green-600 text-white block font-medium" %>
  </div>

  <div id="batches" class="min-w-full mt-8 grid grid-cols-1 md:grid-cols-2 gap-6">
    <% @batches.each do |batch| %>
      <div class="bg-white shadow rounded-lg p-6 border-l-4 border-green-500">
        <div class="flex justify-between items-start">
          <div>
            <h2 class="font-bold text-xl text-gray-900"><%= batch.recipe.title %></h2>
            <p class="text-sm text-gray-500"><%= batch.made_on.strftime("%B %d, %Y") %></p>
          </div>
          <%= link_to "View Details", batch, class: "text-sm text-blue-600 hover:underline" %>
        </div>
        
        <% if batch.notes.present? %>
          <div class="mt-4 text-gray-600 italic text-sm">
            "<%= batch.notes.truncate(100) %>"
          </div>
        <% end %>
      </div>
    <% end %>
    
    <% if @batches.empty? %>
      <p class="text-gray-500">No batches logged yet. Go make something!</p>
    <% end %>
  </div>
</div>
```

In `app/views/batches/new.html.erb`:

```erb
<div class="mx-auto md:w-2/3 w-full">
  <h1 class="font-bold text-4xl">Log a New Batch</h1>

  <%= form_with(model: @batch, class: "contents") do |form| %>
    <% if @batch.errors.any? %>
      <div id="error_explanation" class="bg-red-50 text-red-500 px-3 py-2 font-medium rounded-lg mt-3">
        <h2><%= pluralize(@batch.errors.count, "error") %> prohibited this batch from being saved:</h2>
        <ul>
          <% @batch.errors.each do |error| %>
            <li><%= error.full_message %></li>
          <% end %>
        </ul>
      </div>
    <% end %>

    <div class="my-5">
      <%= form.label :recipe_id, "Which Recipe?" %>
      <%= form.collection_select :recipe_id, current_user.recipes, :id, :title, 
          { prompt: "Select a recipe" }, 
          { class: "block shadow rounded-md border border-gray-200 outline-none px-3 py-2 mt-2 w-full" } %>
    </div>

    <div class="my-5">
      <%= form.label :made_on, "Date Made" %>
      <%= form.date_field :made_on, class: "block shadow rounded-md border border-gray-200 outline-none px-3 py-2 mt-2 w-full" %>
    </div>

    <div class="my-5">
      <%= form.label :notes, "Production Notes (How did it go? Any adjustments?)" %>
      <%= form.text_area :notes, rows: 6, class: "block shadow rounded-md border border-gray-200 outline-none px-3 py-2 mt-2 w-full", placeholder: "e.g. Added a bit more lavender oil for scent. Consistency is perfect." %>
    </div>

    <div class="inline">
      <%= form.submit "Log Batch", class: "rounded-lg py-3 px-5 bg-green-600 text-white inline-block font-medium cursor-pointer" %>
      <%= link_to "Cancel", batches_path, class: "ml-2 rounded-lg py-3 px-5 bg-gray-100 inline-block font-medium" %>
    </div>
  <% end %>
</div>
```

In `app/views/batches/show.html.erb`:

```erb
<div class="mx-auto md:w-2/3 w-full">
  <div class="bg-white shadow rounded-lg p-8 border-l-8 border-green-500">
    <div class="flex justify-between items-start mb-8">
      <div>
        <p class="text-sm font-bold text-gray-500 uppercase tracking-widest mb-1">Batch Log</p>
        <h1 class="font-bold text-4xl text-gray-900"><%= @batch.recipe.title %></h1>
        <p class="text-lg text-gray-600 mt-2">Made on <%= @batch.made_on.strftime("%A, %B %d, %Y") %></p>
      </div>
      <%= link_to "View Recipe", @batch.recipe, class: "bg-blue-50 text-blue-600 px-4 py-2 rounded-lg font-medium hover:bg-blue-100" %>
    </div>

    <div class="mb-10">
      <h2 class="text-sm font-bold text-gray-500 uppercase tracking-widest mb-4">Ingredients Used</h2>
      <div class="bg-gray-50 rounded-xl p-6">
        <ul class="divide-y divide-gray-200">
          <% @batch.recipe.recipe_ingredients.each do |ri| %>
            <li class="py-3 flex justify-between">
              <span class="font-medium text-gray-800"><%= ri.ingredient.name %></span>
              <span class="text-gray-600"><%= ri.quantity %></span>
            </li>
          <% end %>
        </ul>
      </div>
    </div>

    <% if @batch.notes.present? %>
      <div class="mb-10">
        <h2 class="text-sm font-bold text-gray-500 uppercase tracking-widest mb-4">Production Notes</h2>
        <div class="prose prose-green max-w-none text-gray-700 bg-green-50 p-6 rounded-xl italic">
          <%= simple_format @batch.notes %>
        </div>
      </div>
    <% end %>

    <div class="flex justify-between items-center pt-6 border-t border-gray-100">
      <%= link_to "Back to History", batches_path, class: "text-gray-600 hover:underline font-medium" %>
      <div class="flex gap-3">
        <%= button_to "Delete Log", @batch, method: :delete, class: "text-red-600 text-sm hover:underline", data: { confirm: "Are you sure you want to delete this batch log?" } %>
      </div>
    </div>
  </div>
</div>
```

### Step 6: Add Routes

Before we continue, let's add the routes for our new resources. Open `config/routes.rb` and add the new routes:

```ruby
Rails.application.routes.draw do
  # Authentication routes (from Week 2)
  resource :session
  resources :users, only: [:new, :create]
  
  # Existing resources
  resources :ingredients
  resources :recipes
  
  # New Week 4 resources - ADD THESE LINES:
  resources :inventory_items
  resources :batches, only: [:index, :show, :new, :create, :destroy]
  
  # We'll set the root to dashboard in Step 9
  # root "dashboards#show"
end
```

> **Note about `only:`**: For batches, we used `only: [:index, :show, :new, :create, :destroy]` because we don't need `edit` and `update` - once a batch is logged, you typically don't modify it (you'd delete it and create a new one if needed).

### Step 7: Add "Log Batch" Button to Recipes

It's much easier to log a batch if you're already looking at the recipe.

In `app/views/recipes/show.html.erb`, add a button in the action buttons section (usually near the "Edit" link):

```erb
<div class="flex gap-2 mt-6">
  <%= link_to "Edit this recipe", edit_recipe_path(@recipe), class: "rounded-lg py-3 px-5 bg-gray-100 inline-block font-medium" %>
  <%= link_to "Back to recipes", recipes_path, class: "rounded-lg py-3 px-5 bg-gray-100 inline-block font-medium" %>
  
  <%# Add this button to quickly log a batch from the recipe page %>
  <%= link_to "Log a New Batch", new_batch_path(recipe_id: @recipe.id), 
      class: "rounded-lg py-3 px-5 bg-green-600 text-white inline-block font-medium" %>
</div>
```

When you click this, the `new` action in the Batches controller will see the `recipe_id` in the URL and pre-select that recipe in the form!

---

## Part 3: Dashboard

### Step 8: Create Dashboard Controller

The dashboard is the "Home" of your app. It should give you a quick overview of everything.

```bash
rails generate controller Dashboards show
```

Update `app/controllers/dashboards_controller.rb`:

```ruby
class DashboardsController < ApplicationController
  def show
    @recent_recipes = current_user.recipes.order(created_at: :desc).limit(5)
    @recent_batches = current_user.batches.includes(:recipe).order(made_on: :desc).limit(5)
    
    @stats = {
      ingredients: current_user.ingredients.count,
      recipes: current_user.recipes.count,
      inventory: current_user.inventory_items.count,
      batches: current_user.batches.count
    }
  end
end
```

### Step 9: Build Dashboard View

In `app/views/dashboards/show.html.erb`:

```erb
<div class="w-full">
  <div class="flex justify-between items-center mb-8">
    <h1 class="font-bold text-4xl">Welcome back, <%= current_user.email_address.split('@').first.capitalize %>!</h1>
    <div class="text-sm text-gray-500">
      <%= Time.now.strftime("%A, %B %d, %Y") %>
    </div>
  </div>

  <!-- Stats Grid -->
  <div class="grid grid-cols-1 md:grid-cols-4 gap-4 my-8">
    <div class="bg-white p-6 rounded-lg shadow border-t-4 border-blue-500">
      <p class="text-gray-500 uppercase text-xs font-bold">Ingredients</p>
      <p class="text-3xl font-bold"><%= @stats[:ingredients] %></p>
      <%= link_to "View all →", ingredients_path, class: "text-xs text-blue-600 hover:underline mt-2 block" %>
    </div>
    <div class="bg-white p-6 rounded-lg shadow border-t-4 border-green-500">
      <p class="text-gray-500 uppercase text-xs font-bold">Recipes</p>
      <p class="text-3xl font-bold"><%= @stats[:recipes] %></p>
      <%= link_to "View all →", recipes_path, class: "text-xs text-green-600 hover:underline mt-2 block" %>
    </div>
    <div class="bg-white p-6 rounded-lg shadow border-t-4 border-yellow-500">
      <p class="text-gray-500 uppercase text-xs font-bold">Inventory Items</p>
      <p class="text-3xl font-bold"><%= @stats[:inventory] %></p>
      <%= link_to "View all →", inventory_items_path, class: "text-xs text-yellow-600 hover:underline mt-2 block" %>
    </div>
    <div class="bg-white p-6 rounded-lg shadow border-t-4 border-purple-500">
      <p class="text-gray-500 uppercase text-xs font-bold">Total Batches</p>
      <p class="text-3xl font-bold"><%= @stats[:batches] %></p>
      <%= link_to "View all →", batches_path, class: "text-xs text-purple-600 hover:underline mt-2 block" %>
    </div>
  </div>

  <div class="flex flex-col md:flex-row gap-8">
    <!-- Recent Recipes -->
    <div class="flex-1">
      <div class="flex justify-between items-center mb-4">
        <h2 class="font-bold text-2xl">Recent Recipes</h2>
        <%= link_to "New Recipe", new_recipe_path, class: "text-sm bg-blue-50 text-blue-600 px-3 py-1 rounded-full hover:bg-blue-100" %>
      </div>
      <div class="bg-white shadow rounded-lg divide-y">
        <% @recent_recipes.each do |recipe| %>
          <div class="p-4 flex justify-between items-center">
            <div>
              <%= link_to recipe.title, recipe, class: "text-blue-600 hover:underline font-medium" %>
              <p class="text-xs text-gray-400"><%= recipe.product_type %></p>
            </div>
            <span class="text-sm text-gray-500"><%= recipe.created_at.strftime("%b %d") %></span>
          </div>
        <% end %>
        <% if @recent_recipes.empty? %>
          <div class="p-8 text-center">
            <p class="text-gray-500 mb-4">No recipes yet.</p>
            <%= link_to "Create your first recipe", new_recipe_path, class: "text-blue-600 font-medium hover:underline" %>
          </div>
        <% end %>
      </div>
    </div>

    <!-- Recent Batches -->
    <div class="flex-1">
      <div class="flex justify-between items-center mb-4">
        <h2 class="font-bold text-2xl">Recent Batches</h2>
        <%= link_to "Log Batch", new_batch_path, class: "text-sm bg-green-50 text-green-600 px-3 py-1 rounded-full hover:bg-green-100" %>
      </div>
      <div class="bg-white shadow rounded-lg divide-y">
        <% @recent_batches.each do |batch| %>
          <div class="p-4 flex justify-between items-center">
            <div>
              <p class="font-medium text-gray-900"><%= batch.recipe.title %></p>
              <p class="text-xs text-gray-500 italic"><%= batch.notes.truncate(40) if batch.notes.present? %></p>
            </div>
            <div class="text-right">
              <span class="text-sm text-gray-500 block"><%= batch.made_on.strftime("%b %d") %></span>
              <%= link_to "Details", batch, class: "text-xs text-blue-600 hover:underline" %>
            </div>
          </div>
        <% end %>
        <% if @recent_batches.empty? %>
          <div class="p-8 text-center">
            <p class="text-gray-500 mb-4">No batches logged yet.</p>
            <%= link_to "Log your first batch", new_batch_path, class: "text-green-600 font-medium hover:underline" %>
          </div>
        <% end %>
      </div>
    </div>
  </div>

  <!-- Quick Actions -->
  <div class="mt-12 bg-gray-50 p-8 rounded-2xl border-2 border-dashed border-gray-200">
    <h2 class="font-bold text-xl mb-6 text-center text-gray-700">Quick Actions</h2>
    <div class="flex flex-wrap justify-center gap-4">
      <%= link_to "Add New Ingredient", new_ingredient_path, class: "bg-white border border-gray-200 px-6 py-3 rounded-xl shadow-sm hover:shadow-md transition-all font-medium text-gray-700" %>
      <%= link_to "Record Purchase", new_inventory_item_path, class: "bg-white border border-gray-200 px-6 py-3 rounded-xl shadow-sm hover:shadow-md transition-all font-medium text-gray-700" %>
      <%= link_to "Create Recipe", new_recipe_path, class: "bg-white border border-gray-200 px-6 py-3 rounded-xl shadow-sm hover:shadow-md transition-all font-medium text-gray-700" %>
      <%= link_to "Log Production", new_batch_path, class: "bg-white border border-gray-200 px-6 py-3 rounded-xl shadow-sm hover:shadow-md transition-all font-medium text-gray-700" %>
    </div>
  </div>
</div>
```

### Step 10: Set Dashboard as Root Path

Finally, let's make the dashboard the first thing you see when you log in.

In `config/routes.rb`, move the root route to the top and uncomment it:

```ruby
Rails.application.routes.draw do
  # The root route is the "homepage" of your application.
  # By setting it to dashboards#show, users will see their dashboard
  # immediately after logging in.
  root "dashboards#show"
  
  # ... rest of your routes (keep all the resources lines)
end
```

**Important**: If you get an error saying the root route is defined twice, remove the old root route (it probably points to `ingredients#index`).

#### A Note on Navigation

Now that we have so many pages, update your navigation bar in `app/views/layouts/application.html.erb` to include links to all sections:

```erb
<% if authenticated? %>
  <%= link_to "Dashboard", root_path, class: "text-gray-600 hover:text-gray-900 transition-colors" %>
  <%= link_to "My Recipes", recipes_path, class: "text-gray-600 hover:text-gray-900 transition-colors" %>
  <%= link_to "Inventory", inventory_items_path, class: "text-gray-600 hover:text-gray-900 transition-colors" %>
  <%= link_to "Batches", batches_path, class: "text-gray-600 hover:text-gray-900 transition-colors" %>
  <%= link_to "My Ingredients", ingredients_path, class: "text-gray-600 hover:text-gray-900 transition-colors" %>
<% end %>
```

---

## Part 4: Make It Yours

### Step 11: Personalize Your App

Congratulations! You now have a fully functional Island Formulator application with:
- Ingredient tracking with tags
- Recipe builder with photos
- Inventory management
- Batch logging
- A beautiful dashboard

But here's the best part: **it's yours to customize**.

Your app works, but it looks like the tutorial defaults. This is your chance to make it unique and reflect your personal style. Tailwind CSS makes this incredibly easy—no need to write custom CSS files, just change class names!

#### Ideas for Personalization:

**Change the Color Scheme**
The tutorial uses blue as the primary color (`bg-blue-600`). Try changing it to match your style:
- `bg-pink-600` for a warm, feminine feel
- `bg-emerald-600` for natural/organic vibes  
- `bg-purple-600` for something bold and creative
- `bg-orange-600` for energy and warmth

Replace all instances in buttons, links, and borders. For example:
```erb
<%# Before %>
<%= form.submit class: "rounded-lg py-3 px-5 bg-blue-600 text-white..." %>

<%# After %>
<%= form.submit class: "rounded-lg py-3 px-5 bg-emerald-600 text-white..." %>
```

**Adjust the Dashboard Stats**
Change the border colors on the stat cards to match your new theme:
```erb
<%# Current: blue, green, yellow, purple %>
<div class="bg-white p-6 rounded-lg shadow border-t-4 border-pink-500">  <%# Changed to pink %>
```

**Play with Spacing**
Make cards more spacious or compact:
- `p-4` (tight) vs `p-8` (roomy) vs `p-12` (luxurious)
- Try `gap-2` vs `gap-8` in the dashboard grid

**Add Visual Polish**
- Add shadows: `shadow-md`, `shadow-lg`, or `shadow-xl`
- Try gradient buttons: `bg-gradient-to-r from-pink-500 to-purple-500`
- Add hover effects: `hover:scale-105 transform transition-all`
- Use backdrop blur for a modern glass effect: `backdrop-blur-sm bg-white/80`

**Typography Tweaks**
```erb
<%# Try different font weights %>
<h1 class="font-black text-4xl">  <%# Extra bold %>

<%# Or lighter, more elegant %>
<h1 class="font-light text-3xl tracking-wide">
```

**Layout Experiments**
- Change the dashboard grid: `grid-cols-2` instead of `grid-cols-4`
- Make cards full-width on mobile: adjust responsive classes
- Try `rounded-none` for sharp, modern edges vs `rounded-2xl` for soft, friendly feels

#### Where to Start:

1. **Pick one page** to customize first (the dashboard is a great starting point)
2. **Change all instances of one color** to another (find-and-replace `bg-blue-600` with your choice)
3. **Save and refresh** to see changes instantly
4. **Iterate** until you love it!

#### Share Your Style!

Post screenshots in #showcase showing off your customizations. We'd love to see:
- Your color palette choices
- Creative layout tweaks
- Before/after comparisons
- Any unique features you added

> **Tip**: Use the [Tailwind CSS Color Palette](https://tailwindcss.com/docs/customizing-colors) to find colors that work well together. Look for colors with the same number (like `pink-600`, `purple-600`, `teal-600`) for a cohesive palette.

Remember: There's no "wrong" design. If you like it, it's perfect! 🎨

---

## Troubleshooting Common Issues

### 1. "N+1" Queries
You might notice in your server logs that Rails is making a lot of database calls when you view the Inventory or Batch index. This happens because for every item, Rails has to go back to the database to find the name of the Ingredient or Recipe.
**Fix**: Use `.includes(:ingredient)` or `.includes(:recipe)` in your controller, as we did in the steps above. This tells Rails to fetch all the related data in just two queries instead of dozens.

### 2. Date Formatting
If your dates look like `2026-01-26` and you want them to look like `Jan 26, 2026`, use the `.strftime` method:
`<%= item.purchase_date.strftime("%b %d, %Y") %>`
- `%b`: Abbreviated month (Jan)
- `%B`: Full month (January)
- `%d`: Day of the month
- `%Y`: 4-digit year

### 3. Missing Data
If you try to log a batch for a recipe that doesn't exist, or an inventory item for an ingredient you haven't created yet, the app will crash.
**Fix**: Always ensure you have created the **Template Data** (Ingredients and Recipes) before trying to create the **Transactional Data** (Inventory and Batches).

### 4. "undefined method 'inventory_items' for User"
If you see this error when visiting `/inventory_items`, you forgot to add the association to your User model.
**Fix**: Add `has_many :inventory_items, dependent: :destroy` to `app/models/user.rb`.

### 5. "undefined method 'batches' for User"
Similar to #4, but for batches.
**Fix**: Add `has_many :batches, dependent: :destroy` to `app/models/user.rb`.

### 6. "undefined local variable or method 'current_user'"
You haven't added the `current_user` helper method to your Authentication concern yet.
**Fix**: Follow Step 5 from Week 3 tutorial to add `current_user` method to `app/controllers/concerns/authentication.rb`.

---

## Complete Workflow Test

Now that everything is connected, try this full workflow:
1. Go to **Ingredients** and make sure you have "Shea Butter".
2. Go to **Inventory** and add a "16oz jar of Sky Organics Shea Butter" that you bought today.
3. Go to **Recipes** and create a "Simple Body Butter" recipe using Shea Butter.
4. On the "Simple Body Butter" page, click **Log a New Batch**.
5. Save the batch.
6. Go to your **Dashboard** (the home icon or root URL) and see your stats update!

---

## Git Commits

Don't forget to save your progress! Run these commands one at a time:

```bash
git add .
```

```bash
git commit -m "feat(inventory): add inventory item tracking"
```

```bash
git commit -m "feat(batches): add batch logging for recipes"
```

```bash
git commit -m "feat(dashboard): add user dashboard with summary stats"
```

```bash
git commit -m "design: personalize app with custom Tailwind styles"
```
