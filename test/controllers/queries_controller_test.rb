require 'test_helper'

class QueriesControllerTest < ActionController::TestCase
  
  def setup
  	@user = users(:example)
  	@query = queries(:hospital)
  end

  test "should redirect create when not logged in" do
  	assert_no_difference 'Query.count' do 
  		post :create, query: { description: "lorem ipsum" }
  	end
  	assert_redirected_to login_url
  end

  test "should redirect destroy when not logged in" do
  	assert_no_difference 'Query.count' do 
  		post :destroy, id: @query
  	end
  	assert_redirected_to login_url
  end

  test "accessing queries after login" do 
  	log_in_as(@user)
  	get :list
  	assert_response :success
  end

end
