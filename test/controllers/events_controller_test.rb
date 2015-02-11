require 'test_helper'

class EventsControllerTest < ActionController::TestCase

	#Test data initialized in test_helper.rb#setup
	#and truncated while teardown

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
  	assert_difference('Event.count') do
  		post :create, event: test_event
  	end
  	assert_response :redirect
  	assert_equal "Event created", flash[:notice]
  	assert_redirected_to events_path
  	assert_includes assigns(:event).users, @non_participant_user
  end

  test "user tries to create event with invalid data and is sent back to new page" do
  	test_event = {name: nil}
  	post :create, event: test_event
  	assert_response :success
  	assert_template :new
  	assert_equal "Event is invalid. Please correct", flash[:notice]
  end

  test "organizer can edit event" do
  	sign_in @organizer
  	get :edit, id: @event.id
  	assert_response :success
  	assert_template :edit
  	assert assigns(:event)
  end

  test "participant cannot edit event" do
  	sign_in @user1
  	get :edit, id: @event.id
  	assert_response :forbidden
  end

  test "non participant cannot edit event" do
  	get :edit, id: @event.id
  	assert_response :forbidden
  end

  test "organizer can update event" do
  	sign_in @organizer
   	test_event = {name: "Randers", from_date: Date.new(2012, 11, 2), 
			to_date: Date.new(2012, 11, 4), description: "Come Malaka event in a different country", 
			event_currency: "EUR", organizer_id: @organizer.id}
  	put :update, id: @event.id, event: test_event
  	assert_response :redirect
  	assert_redirected_to events_path
  	assert_equal "Event updated", flash[:notice]
  end

  test "organizer tries to update event with invalid data and is sent back to edit page" do
  	sign_in @organizer
   	test_event = {name: nil}
  	put :update, id: @event.id, event: test_event
  	assert_response :success
  	assert_template :edit
  	assert_equal "Event cannot be updated with invalid data. Please correct", flash[:notice]
  end

  test "participant cannot update event" do
  	sign_in @user1
    test_event = {name: "Randers", from_date: Date.new(2012, 11, 2), 
			to_date: Date.new(2012, 11, 4), description: "Come Malaka event in a different country", 
			event_currency: "EUR", organizer_id: @organizer.id}
  	put :update, id: @event.id, event: test_event
  	assert_response :forbidden
  end

  test "non participant cannot update event" do
    test_event = {name: "Randers", from_date: Date.new(2012, 11, 2), 
			to_date: Date.new(2012, 11, 4), description: "Come Malaka event in a different country", 
			event_currency: "EUR", organizer_id: @organizer.id}
  	put :update, id: @event.id, event: test_event
  	assert_response :forbidden
  end

  test "organizer can delete event" do
  	sign_in @organizer
  	@event.items = [] #make event deletable by removing its items
  	assert_difference('Event.count', -1) do
	  	delete :destroy, id: @event.id
  	end	
  	assert_response :redirect
  	assert_redirected_to events_path
  	assert_equal "Event deleted", flash[:notice]
  end

  test "organizer must fail to delete an event that contains items" do
  	sign_in @organizer
  	assert_no_difference('Event.count') do
	  	delete :destroy, id: @event.id
  	end	
  	assert_response :redirect
  	assert_redirected_to events_path
  	assert_equal "Event cannot be deleted. Posted items exist.", flash[:notice]
  end

  test "participant cannot delete event" do
  	sign_in @user1
  	@event.items = [] #make event deletable by removing its items
  	delete :destroy, id: @event.id
  	assert_response :forbidden
  end

  test "non participant cannot delete event" do
  	@event.items = [] #make event deletable by removing its items
	  delete :destroy, id: @event.id
  	assert_response :forbidden
  end

  test "organizer can display event" do
  	sign_in @organizer
  	get :show, id: @event.id
  	assert_response :success
  	assert assigns(:event)
  end

  test "event participant can display event" do
  	sign_in @user1
  	get :show, id: @event.id
  	assert_response :success
  	assert assigns(:event)
  end

  test "non participant cannot display event" do
  	get :show, id: @event.id
  	assert_response :forbidden
  end

  test "organizer can see all event items" do
  	sign_in @organizer
  	get :event_all_items, event_id: @event.id
  	assert_response :success
  	assert assigns(:items)
  end

  test "participant can see all event items" do
  	sign_in @user1
  	get :event_all_items, event_id: @event.id
  	assert_response :success
  	assert assigns (:items)
  end

  test "non participant cannot see all event items" do
  	get :event_all_items, event_id: @event.id
  	assert_response :forbidden
  	assert_nil assigns(:items)
  end

  test "organizer can see expense report" do
  	sign_in @organizer
  	get :expense_report, event_id: @event.id
  	assert_response :success
  	assert assigns(:event)
  	assert assigns(:participants)
  	assert assigns(:items)
  end

  test "participant can see expense report" do
  	sign_in @user1
  	get :expense_report, event_id: @event.id
  	assert_response :success
  	assert assigns(:event)
  	assert assigns(:participants)
  	assert assigns(:items)  end

  test "non participant cannot see expense report" do
  	get :expense_report, event_id: @event.id
  	assert_response :forbidden
  	assert_nil assigns(:participants)
  	assert_nil assigns(:items)
  end

end
