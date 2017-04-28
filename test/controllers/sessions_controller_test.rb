require 'test_helper'

class SessionsControllerTest < ActionController::TestCase
    include Rails.application.routes.url_helpers

  #Test data initialized in test_helper.rb#setup
  #and truncated while teardown

  def setup
    super
    @request.env["devise.mapping"] = Devise.mappings[:user]
    sign_in @user2
  end

  def teardown
    super
    sign_out @user2
  end


  test "user cannot log in when account is cancelled" do 
    @user2.deleted_at = Time.current
    @user2.save 
    post :create, params: { user: { email: "user2@event.com", password: "user2345", remember_me: '0' } }
    assert_response :redirect#, "Response must be a redirect" 
    assert_redirected_to new_user_session_path, "Redirect must be new_user_session_path" 
    assert_equal "Your account is deactivated. Contact support to re-activate your account.", flash[:alert] 
  end  

end

