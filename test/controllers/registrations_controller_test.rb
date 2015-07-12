require 'test_helper'

class RegistrationsControllerTest < ActionController::TestCase
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

  test "user cancels account" do
    delete :destroy, id: @user2.id
    assert_response :redirect, "Response must be redirect"
    assert_redirected_to root_path,"Redirect must be root_path (welcome homepage)"
    assert_equal "Bye! Your account has been successfully cancelled. We hope to see you again soon.", flash[:notice]
  end

end
