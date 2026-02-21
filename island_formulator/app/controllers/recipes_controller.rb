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
      :photo, 
      recipe_ingredients_attributes: [:id, :ingredient_id, :quantity, :_destroy]
    )
  end
end