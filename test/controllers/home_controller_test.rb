require 'test_helper'

class HomeControllerTest < ActionController::TestCase

  test "unauthenticated user must get index" do
    get :index
    assert_response :success, "Respnse must be success"
    assert_template :index
    # Test the view
    assert_select "title", "Welcome to Come Malaka"
    assert_select "h2", "Packoooook Malaka"
    assert_select "p", 'Welcome to Come Malaka. Sign in or sign up for an account to start using the Come Malaka app.'
    assert_select "p a", 2
    assert_select "a:match('href', ?)", new_user_session_path
    assert_select "a:match('href', ?)", new_user_registration_path
  end

  test "authenticated user must be redirected to event's page" do
  	sign_in @organizer
  	get :index
  	assert_response :redirect, "Response must be redirect"
  	assert_redirected_to events_path, "User must be redirected to events_path"
  end

end
