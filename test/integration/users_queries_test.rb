require 'test_helper'

class UsersQueriesTest < ActionDispatch::IntegrationTest
  def setup
  	@user = users(:example)
  	@query = queries(:hospital)
  end

  test "accessing queries without login and friendly fordwarding" do 
  	get queries_path
  	assert_redirected_to login_url
  	log_in_as(@user)
  	follow_redirect!
  	assert_template 'queries/list'
  end

end
