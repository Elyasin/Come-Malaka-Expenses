require 'test_helper'

class EventsControllerTest < ActionController::TestCase

	def setup
		super
		sign_in @non_participant_user
	end

	def teardown
		super
		sign_out @non_participant_user
	end

  test "unauthenticated user for any event controller action must be redirected to sign in page" do

  	sign_out @non_participant_user

    get :index
    assert_response :redirect
    assert_redirected_to new_user_session_path

    get :show, id: @event.id
    assert_response :redirect
    assert_redirected_to new_user_session_path

    get :edit, id: @event.id
    assert_response :redirect
    assert_redirected_to new_user_session_path

    put :update, id: @event.id
    assert_response :redirect
    assert_redirected_to new_user_session_path

    get :new
    assert_response :redirect
    assert_redirected_to new_user_session_path

    post :create
    assert_response :redirect
    assert_redirected_to new_user_session_path

    delete :destroy, id: @event.id
    assert_response :redirect
    assert_redirected_to new_user_session_path

    get :event_all_items, event_id: @event.id
    assert_response :redirect
    assert_redirected_to new_user_session_path

    get :expense_report, event_id: @event.id
    assert_response :redirect
    assert_redirected_to new_user_session_path
  end

	test "user can see events page" do
		get :index
		assert_response :success
		assert_not_nil assigns(:events)
	end

  test "user can see new page" do
  	get :new
  	assert_response :success
  	assert_not_nil assigns(:event)
  end

  test "user can create valid event and becomes participant" do
  	test_event = {name: "Test event", from_date: Date.today, to_date: Date.today+3, description: "Test description", 
  		event_currency: "EUR", organizer_id: @organizer.id}
  	post :create, event: test_event
  	assert_response :redirect
  	assert_equal "Event created", flash[:notice]
  	assert_redirected_to events_path
  	assert_includes assigns(:event).users, @non_participant_user
  end

  test "user tries to create an invalid event and is sent back to new page" do
  	test_event = {name: nil}
  	post :create, event: test_event
  	assert_response :success
  	assert_template :new
  	assert_equal "Event is invalid. Please correct", flash[:notice]
  end

  

end
