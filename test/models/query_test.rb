require 'test_helper'

class QueryTest < ActiveSupport::TestCase
  def setup
  	@user = users(:example)
  	@query = @user.queries.build(description: "Lorem ipsum")
  end

  test "should be valid" do 
  	assert @query.valid?
  end

  test "user ID should be present" do 
  	@query.user_id = nil
  	assert_not @query.valid?
  end	

  test "description should be present" do 
  	@query.description = " "
  	assert_not @query.valid?
  end

end
