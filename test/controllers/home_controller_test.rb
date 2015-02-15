require 'test_helper'

class HomeControllerTest < ActionController::TestCase

  test "unauthenticated user must get index" do
    get :index
    assert_response :success, "Respnse must be success"
    assert_template :index
  end

  test "authenticated user must be redirected to event's page" do
  	sign_in @organizer
  	get :index
  	assert_response :redirect, "Response must be redirect"
  	assert_redirected_to events_path, "User must be redirected to events_path"
  end

end
