require 'test_helper'

class DistributionListsControllerTest < ActionController::TestCase
  setup do
    @distribution_list = distribution_lists(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:distribution_lists)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create distribution_list" do
    assert_difference('DistributionList.count') do
      post :create, :distribution_list => @distribution_list.attributes
    end

    assert_redirected_to distribution_list_path(assigns(:distribution_list))
  end

  test "should show distribution_list" do
    get :show, :id => @distribution_list.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => @distribution_list.to_param
    assert_response :success
  end

  test "should update distribution_list" do
    put :update, :id => @distribution_list.to_param, :distribution_list => @distribution_list.attributes
    assert_redirected_to distribution_list_path(assigns(:distribution_list))
  end

  test "should destroy distribution_list" do
    assert_difference('DistributionList.count', -1) do
      delete :destroy, :id => @distribution_list.to_param
    end

    assert_redirected_to distribution_lists_path
  end
end
