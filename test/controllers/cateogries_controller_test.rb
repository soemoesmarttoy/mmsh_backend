require "test_helper"

class CateogriesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get cateogries_index_url
    assert_response :success
  end

  test "should get create" do
    get cateogries_create_url
    assert_response :success
  end

  test "should get update" do
    get cateogries_update_url
    assert_response :success
  end

  test "should get delete" do
    get cateogries_delete_url
    assert_response :success
  end
end
