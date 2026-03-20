class FavoritesController < ApplicationController
  before_action :require_authentication

  def create
    recipe = Recipe.find(params[:recipe_id])
    current_user.favorites.find_or_create_by(recipe: recipe)
    redirect_back fallback_location: recipe_path(recipe)
  end

  def destroy
    recipe = Recipe.find(params[:recipe_id])
    favorite = current_user.favorites.find_by(recipe: recipe)
    favorite&.destroy
    redirect_back fallback_location: recipe_path(recipe)
  end
end
