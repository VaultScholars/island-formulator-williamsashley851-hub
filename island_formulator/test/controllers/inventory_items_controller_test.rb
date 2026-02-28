require "test_helper"

class InventoryItemsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @inventory_item = inventory_items(:one)
  end

  test "should get index" do
    get inventory_items_url
    assert_response :success
  end

  test "should get new" do
    get new_inventory_item_url
    assert_response :success
  end

  test "should create inventory_item" do
    assert_difference("InventoryItem.count") do
      post inventory_items_url, params: { inventory_item: {} }
    end

    assert_redirected_to inventory_item_url(InventoryItem.last)
  end

  test "should show inventory_item" do
    get inventory_item_url(@inventory_item)
    assert_response :success
  end

  test "should get edit" do
    get edit_inventory_item_url(@inventory_item)
    assert_response :success
  end

  test "should update inventory_item" do
    patch inventory_item_url(@inventory_item), params: { inventory_item: {} }
    assert_redirected_to inventory_item_url(@inventory_item)
  end

  test "should destroy inventory_item" do
    assert_difference("InventoryItem.count", -1) do
      delete inventory_item_url(@inventory_item)
    end

    assert_redirected_to inventory_items_url
  end
end
