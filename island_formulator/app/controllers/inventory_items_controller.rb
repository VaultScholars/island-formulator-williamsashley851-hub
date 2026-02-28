class InventoryItemsController < ApplicationController
  before_action :require_authentication  
  before_action :set_inventory_item, only: %i[ show edit update destroy ]

  def index
    @inventory_items = Current.user.inventory_items.includes(:ingredient).order(purchase_date: :desc)
  end

  def show
  end

  def new
    @inventory_item = Current.user.inventory_items.build
  end

  def edit
  end

  def create
    @inventory_item = Current.user.inventory_items.build(inventory_item_params)

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
      @inventory_item = Current.user.inventory_items.find(params[:id])
    end

    def inventory_item_params
      params.require(:inventory_item).permit(:ingredient_id, :brand, :size, :location, :purchase_date, :notes, :photo)
    end
end


