[![Review Assignment Due Date](https://classroom.github.com/assets/deadline-readme-button-22041afd0340ce965d47ae6ef1cefeee28c7c493a6346c4f15d667ab976d596c.svg)](https://classroom.github.com/a/VykKk-y9)
# Island Formulator
**Island Formulator** is a specialized inventory management and recipe-building tool designed specifically for these creators. It helps them track their "pantry" of ingredients, document their secret formulas, and log every batch they produce.

# Week 1: Your First Rails App - Ingredient Tracker

Welcome to Week 1 of the Island Formulator project! This week, we're going to build the foundation of our application: the **Ingredient Tracker**. 

By the end of this tutorial, you'll have a working web application where you can record, view, edit, and delete the raw ingredients you use for your hair care formulations.

**Time Estimate**: 3-4 hours

**What You'll Build**: A "Mini-App" within our project that handles CRUD operations for Ingredients, styled with Tailwind CSS.

---

## Overview: What We're Building

Imagine you're standing in your lab (or kitchen!) surrounded by bottles of Jojoba oil, jars of Shea butter, and essential oils. You need a way to keep track of what you have, what they do, and any special notes for each.

We are building a digital version of that shelf. 

**Key Features:**
*   A list view of all your ingredients.
*   Detailed pages for each ingredient (Description, Category, Notes).
*   The ability to add new ingredients and update existing ones.
*   Form validations to ensure you don't save "empty" ingredients.
*   A clean, modern interface using Tailwind CSS.

---

## Step 1: Create the Island Formulator App

In Week 0, you set up your environment and created a "test app." Now, it's time for the real thing.

### Important: Working Within Your Assignment Repository

You should have already accepted the Week 1 GitHub Classroom assignment and cloned it to your computer. **You'll create your Rails app INSIDE your assignment repository** so everything is organized together.

### Navigate to Your Assignment Repository

First, make sure you're in your Week 1 assignment folder:

```bash
cd ~/island-formulator-yourusername  # Replace with your actual assignment folder name
```

**Not sure where it is?** Run `pwd` to see your current location. You should see something like `/home/yourusername/week1-ingredient-tracker-yourusername`.

### Understanding `rails new`

Now, create the Rails app inside this assignment repository:

```bash
rails new island_formulator --database=postgresql --css=tailwind
```

**What does this command do?**
*   `rails new island_formulator`: Tells Rails to create a new folder named `island_formulator` and fill it with the standard Rails file structure.
*   `--database=postgresql`: Tells Rails we want to use PostgreSQL as our database. This is important because professional hosting services (like Render or Heroku) prefer Postgres over the default SQLite.
*   `--css=tailwind`: Tells Rails to pre-configure **Tailwind CSS**, a "utility-first" CSS framework that makes styling our app much faster.

### The File Structure
Once the command finishes, move into your new project:
```bash
cd island_formulator
```

Your folder structure now looks like this:
```
island-formulator-yourusername/
├── README.md                    # This tutorial file
└── island_formulator/           # Your Rails app (created just now)
    ├── app/
    ├── config/
    ├── db/
    └── ... (all Rails files)
```

If you open the `island_formulator` folder in VS Code (`code .`), you'll see a lot of files. Don't panic! Here are the most important ones for now:
*   `app/`: This is where 90% of your work happens. It contains your Models, Views, and Controllers (MVC).
*   `config/routes.rb`: The "traffic cop" of your app. It decides which URL goes to which part of your code.
*   `db/`: Contains your database configuration and "migrations" (instructions on how to build your database tables).

### Verification
Run `bin/rails server` and visit `http://localhost:3000`. You should see the "Yay! You're on Rails!" welcome page.

---

## Step 2: Understanding MVC Architecture

Before we start generating code, we need to understand **MVC**. It's the "Golden Rule" of Rails and the secret to why Rails apps are so organized.

### The Restaurant Analogy
Think of a restaurant:
1.  **The View (The Table)**: This is what the customer sees. The menu, the plates, the presentation, and the ambiance. In Rails, these are your **HTML** files (specifically `.html.erb` files). They are responsible for the "look and feel."
2.  **The Controller (The Waiter)**: The waiter takes your order (the URL you clicked) and goes to the kitchen. They decide what needs to happen next. Should they get a drink? Should they tell the chef to start cooking? The Controller handles the **logic** and coordinates between the user and the rest of the app.
3.  **The Model (The Chef)**: The chef knows where the food is kept (the **Database**) and how to prepare it. They don't talk to the customer; they just handle the data. The Model is responsible for the **data rules** (like validations) and talking to the database.

### The Request-Response Cycle
When you type `localhost:3000/ingredients` into your browser, here is what happens:
1.  **The Router**: Rails looks at the URL and checks `config/routes.rb`. It sees that `/ingredients` should go to the `IngredientsController`.
2.  **The Controller**: The `index` action in the `IngredientsController` is triggered. It says, "I need a list of all ingredients."
3.  **The Model**: The Controller calls `Ingredient.all`. The Model goes to the PostgreSQL database, fetches all the rows from the `ingredients` table, and gives them back to the Controller.
4.  **The View**: The Controller takes that list and hands it to the `index.html.erb` view. The view loops through the list and creates the HTML.
5.  **The Browser**: Rails sends that HTML back to your browser, and you see your list of ingredients!

### Why MVC?
By separating these concerns, your code stays clean. If you want to change how the page looks, you only touch the **View**. If you want to change how an ingredient is saved, you only touch the **Model**. This "Separation of Concerns" is what makes Rails so powerful for large projects.

---

## Step 3: Generate the Ingredient Scaffold

Now, let's build our Ingredient system. Instead of creating every file by hand, we'll use a powerful Rails tool called a **Scaffold**.

### What is a Scaffold?
A scaffold is a generator that creates a "starter kit" for a specific piece of data. It creates the Model, the Controller, the Views, and the Database instructions all at once.

### Running the Generator
Run this command in your terminal:

```bash
rails generate scaffold Ingredient name:string category:string description:text notes:text
```

**Breakdown:**
*   `Ingredient`: The name of our data model (always singular).
*   `name:string`: A short piece of text.
*   `category:string`: Another short piece of text (e.g., "Oil", "Butter").
*   `description:text`: A longer area for descriptions.
*   `notes:text`: A longer area for personal notes.

### What Files Were Created?
Look at your terminal output. Rails created about 15 files! The big ones are:
*   `app/models/ingredient.rb`: The "Chef" for our ingredients.
*   `app/controllers/ingredients_controller.rb`: The "Waiter" handling requests.
*   `app/views/ingredients/`: A folder full of HTML templates (`index`, `show`, `new`, `edit`).
*   `db/migrate/202XXXXXX_create_ingredients.rb`: The instructions to create the database table.

---

## Step 4: Understanding Migrations

Even though we ran the generator, our database doesn't know about "Ingredients" yet. We have a "Migration" file, which is like a blueprint. We need to tell Rails to actually "build" it.

First, create the database:
```bash
rails db:create
```

Then, run the migration:
```bash
rails db:migrate
```

**Understanding What Just Happened:**
Rails looked in `db/migrate/`, found the instructions for the `ingredients` table, and executed them in PostgreSQL. You can check the status anytime with:
```bash
rails db:migrate:status
```
You should see "up" next to the `CreateIngredients` migration.

---

## Step 5: Start Your App

It's time to see your creation!

1.  Start the server: `bin/rails server`
2.  Open your browser to: `http://localhost:3000/ingredients`

**Wait, what's the URL?**
Because we used a scaffold, Rails automatically added `resources :ingredients` to your `config/routes.rb` file. This creates a set of standard URLs for us.

You should see a page titled "Ingredients" with a "New ingredient" link.

---

## Step 6: Testing CRUD Operations

**CRUD** stands for **C**reate, **R**ead, **U**pdate, and **D**elete. These are the four basic things you can do with any data.

1.  **Create**: Click "New ingredient". Fill in "Jojoba Oil" for the name and "Oil" for the category. Click "Create Ingredient".
2.  **Read**: You are now on the "Show" page for Jojoba Oil. Go back to the list to see it there too.
3.  **Update**: Click "Edit this ingredient". Change the category to "Carrier Oil". Click "Update Ingredient".
4.  **Delete**: Click on the ingredient to show it, then click "Destroy this ingredient". (Note: In Rails 8, this might be a button that says "Destroy this ingredient").

**Verification**: Ensure you can perform all four actions without errors.

---

## Step 7: Add Validations

Right now, you can save an ingredient with no name. That's bad data! Let's fix the "Chef" (the Model) so it refuses to save invalid ingredients.

Open `app/models/ingredient.rb` and add these lines:

```ruby
class Ingredient < ApplicationRecord
  validates :name, presence: true
  validates :category, presence: true
end
```

### Understanding Validations
Validations are rules that run before data is saved to the database. `presence: true` means the field cannot be empty.

### Test It
Go back to your browser, try to create a new ingredient, but leave the name blank. When you click "Create", Rails will stop you and show an error message: *"Name can't be blank"*.

---

## Step 8: Style with Tailwind

Our app works, but it looks like a 1990s website. Let's use Tailwind CSS to make it beautiful.

Tailwind uses "utility classes." Instead of writing CSS in a separate file, you add classes directly to your HTML.

### The "Before" State
When you first generate a scaffold, Rails creates basic views. They are functional but plain. For example, the list of ingredients is just a simple table or a list of paragraphs.

### Example: Styling the Index Page
Open `app/views/ingredients/index.html.erb`. Let's wrap everything in a nice container and turn the list into a grid of cards.

**Before:**
```erb
<p style="color: green"><%= notice %></p>
<h1>Ingredients</h1>
<div id="ingredients">
  <% @ingredients.each do |ingredient| %>
    <%= render ingredient %>
    <p>
      <%= link_to "Show this ingredient", ingredient %>
    </p>
  <% end %>
</div>
<%= link_to "New ingredient", new_ingredient_path %>
```

**After (Tailwind Version):**
```erb
<div class="container mx-auto mt-10 px-5">
  <div class="flex justify-between items-center mb-10">
    <h1 class="text-4xl font-extrabold text-gray-900">My Ingredient Shelf</h1>
    <%= link_to "Add New Ingredient", new_ingredient_path, 
        class: "bg-emerald-600 hover:bg-emerald-700 text-white font-bold py-3 px-6 rounded-lg shadow-md transition duration-200" %>
  </div>

  <div id="ingredients" class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
    <% @ingredients.each do |ingredient| %>
      <div class="bg-white shadow-lg rounded-xl p-6 border border-gray-100 hover:shadow-xl transition-shadow duration-300">
        <div class="mb-4">
          <span class="inline-block px-3 py-1 text-xs font-semibold tracking-wide text-emerald-800 uppercase bg-emerald-100 rounded-full">
            <%= ingredient.category %>
          </span>
        </div>
        <h2 class="text-xl font-bold text-gray-800 mb-2"><%= ingredient.name %></h2>
        <p class="text-gray-600 line-clamp-3 mb-4"><%= ingredient.description %></p>
        
        <div class="mt-auto pt-4 border-t border-gray-100 flex justify-between items-center">
          <%= link_to "View Details", ingredient, class: "text-emerald-600 font-medium hover:text-emerald-800 transition-colors" %>
          <span class="text-gray-400 text-sm">#<%= ingredient.id %></span>
        </div>
      </div>
    <% end %>
  </div>
</div>
```

### Key Tailwind Classes Explained:
*   **Layout**: `container mx-auto` centers your content. `grid grid-cols-1 md:grid-cols-3` makes it responsive (1 column on phones, 3 on laptops).
*   **Spacing**: `mt-10` (margin top), `px-5` (padding left/right), `mb-10` (margin bottom), `gap-8` (space between grid items).
*   **Typography**: `text-4xl` (large text), `font-extrabold` (very thick), `text-gray-900` (almost black).
*   **Components**: `bg-white shadow-lg rounded-xl` creates the "card" look. `bg-emerald-600` gives us a nice botanical green color.
*   **Interactivity**: `hover:bg-emerald-700` and `transition duration-200` make the buttons feel "alive" when you interact with them.

### Styling the Form
Don't stop at the index page! Open `app/views/ingredients/_form.html.erb` and add classes to your labels and inputs.

**Pro Tip**: For inputs, use classes like `block w-full rounded-md border-gray-300 shadow-sm focus:border-emerald-500 focus:ring-emerald-500`.

### Understanding "Utility-First"
In traditional CSS, you might create a class called `.card` and put 10 lines of CSS inside it. In Tailwind, you apply small, single-purpose classes (utilities) directly to the element. This feels strange at first, but it means you never have to leave your HTML file to style your app!

---

## Step 9: Create Seed Data

It's annoying to manually type in 10 ingredients every time you reset your database. We can automate this using the `db/seeds.rb` file.

### Why Use Seeds?
Seeds are perfect for:
1.  **Development**: Quickly populating your app with realistic data so you can see how your layout looks.
2.  **Initial Setup**: Adding required data (like categories or admin users) when the app is first deployed.

Open `db/seeds.rb` and add some sample data:

```ruby
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
```

### Running the Seeds
Run this command in your terminal:
```bash
rails db:seed
```

**Verification**: Refresh your browser at `/ingredients`. You should see your shelf populated with these 7 ingredients, all beautifully styled in your new grid!

---

## Step 10: Commit and Submit Your Work

You've done a lot of work! Let's save it using Git and submit your assignment.

### What is Git?
Git is a "Version Control System." It tracks every change you make to your code. If you make a mistake, you can go back in time.

### The Submission Workflow

Since you've been working inside the `island_formulator` folder, we need to go back to the assignment repository root to commit everything.

1.  **Navigate back to assignment root**:
    ```bash
    cd ..  # This takes you back to island-formulator-yourusername/
    ```

2.  **Check status**: 
    ```bash
    git status
    ```
    *   This shows you which files have changed. You should see the entire `island_formulator/` folder listed.

3.  **Stage changes**: 
    ```bash
    git add island_formulator
    ```
    *   This tells Git you want to include all the Rails app files in your next save point.

4.  **Commit**: 
    ```bash
    git commit -m "Complete Week 1: Ingredient Tracker with CRUD and validations"
    ```
    *   The `-m` stands for "message." Always write a clear, descriptive message about what you did.

5.  **Push to GitHub (Submit Assignment)**:
    ```bash
    git push origin main
    ```
    *   This uploads your work to GitHub. Your instructor can now see your completed assignment!

### Understanding the Commit Message
We use clear, descriptive commit messages:
*   "Complete Week 1" - tells what milestone you reached
*   "Ingredient Tracker with CRUD and validations" - describes what features you built

**Verification**: 
- Run `git log` to see your commit history. You should see your new commit at the top!
- Visit your GitHub assignment repository in your browser. You should see the `island_formulator` folder with all your Rails files.

**🎉 Assignment Submitted!** Your instructor can now check your work.

---

## What You Learned
*   **MVC Architecture**: How Rails separates data (Model), logic (Controller), and presentation (View).
*   **Scaffolding**: Using generators to jumpstart development.
*   **Migrations**: Managing your database schema over time.
*   **Validations**: Ensuring your data is clean and reliable.
*   **Tailwind CSS**: Building modern UIs without writing custom CSS files.
*   **Seeds**: Automating the creation of sample data.
*   **Git**: Saving your progress and tracking changes.

---

## Common Issues

**1. "Database 'island_formulator_development' does not exist"**
*   **Fix**: Run `rails db:create`.

**2. "Pending Migration Error"**
*   **Fix**: Run `rails db:migrate`.

**3. Tailwind styles aren't showing up**
*   **Fix**: Make sure you are running the server using `bin/dev` instead of `bin/rails server` if you are using the standard Rails 8 Tailwind setup, as `bin/dev` starts the CSS watcher.



