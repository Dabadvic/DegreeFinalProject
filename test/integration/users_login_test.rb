  require 'test_helper'

class UsersLoginTest < ActionDispatch::IntegrationTest

	def setup
		@user = users(:example)
	end
  
  test "login with invalid info" do 
  	get login_path 	# 1. Visit login path
  	assert_template 'sessions/new' # 2. Verify that new sessions form renders properly
  	post login_path, session: { email: "", password: "" } # 3. Post to the path invalid info
  	assert_template 'sessions/new'	# 4. Verify it reloads the page
  	assert_not flash.empty?	# 5. Verify a flash message appears
  	get root_path	# 6. Visit root path
  	assert flash.empty?	# 7. Verify that the flash message doesn't appear
  end

  test "login with valid info followed by logout" do
  	get login_path
  	post login_path, session: { email: @user.email, password: 'password' }
    assert is_logged_in?
  	assert_redirected_to @user
  	follow_redirect!
  	assert_template 'users/show'
  	assert_select "a[href=?]", login_path, count: 0
  	assert_select "a[href=?]", logout_path
  	assert_select "a[href=?]", user_path(@user)
    delete logout_path
    assert_not is_logged_in?
    assert_redirected_to root_url
    # Simulate a user clicking logout in a second window.
    delete logout_path

    follow_redirect!
    assert_select "a[href=?]", login_path
    assert_select "a[href=?]", logout_path, count: 0
    assert_select "a[href=?]", user_path(@user), count: 0
  end

  test "login with remembering" do
    log_in_as(@user, remember_me: '1')
    assert_not_nil cookies['remember_token']
  end

  test "login without remembering" do
    log_in_as(@user, remember_me: '0')
    assert_nil cookies['remember_token']
  end

end
