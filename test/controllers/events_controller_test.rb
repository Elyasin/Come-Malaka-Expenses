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
    assert_response :redirect, "Response must be redirect"
    assert_redirected_to new_user_session_path, "Redirect must be new_user_session_path"

    get :show, id: @event.id
    assert_response :redirect, "Response must be redirect"
    assert_redirected_to new_user_session_path, "Redirect must be new_user_session_path"

    get :edit, id: @event.id
    assert_response :redirect, "Response must be redirect"
    assert_redirected_to new_user_session_path, "Redirect must be new_user_session_path"

    assert_no_difference('Event.count', "Event must not be created") do
      put :update, id: @event.id
    end
    assert_response :redirect, "Response must be redirect"
    assert_redirected_to new_user_session_path, "Redirect must be new_user_session_path"

    get :new
    assert_response :redirect, "Response must be redirect"
    assert_redirected_to new_user_session_path, "Redirect must be new_user_session_path"

    assert_no_difference('Event.count', "Event must not be created") do
      post :create
    end
    assert_response :redirect, "Response must be redirect"
    assert_redirected_to new_user_session_path, "Redirect must be new_user_session_path"

    assert_no_difference('Event.count', "Event must not be created") do
      delete :destroy, id: @event.id
    end
    assert_response :redirect, "Response must be redirect"
    assert_redirected_to new_user_session_path, "Redirect must be new_user_session_path"

    get :event_all_items, event_id: @event.id
    assert_response :redirect, "Response must be redirect"
    assert_redirected_to new_user_session_path, "Redirect must be new_user_session_path"

    get :expense_report, event_id: @event.id
    assert_response :redirect, "Response must be redirect"
    assert_redirected_to new_user_session_path, "Redirect must be new_user_session_path"
  end

	test "organizer can see events page" do
    sign_in @organizer
		get :index
		assert_response :success, "Response must be success"
    assert_template :index, "Index page must be rendered"
		assert_not_nil assigns(:events), "Events must be assigned"
    assert_equal 1, assigns(:events).length, "Event participant must see event"
	end

  test "participant can see events page" do
    sign_in @user1
    get :index
    assert_response :success, "Response must be success"
    assert_template :index, "Index page must be rendered"
    assert_not_nil assigns(:events), "Events must be assigned"
    assert_equal 1, assigns(:events).length, "Event participant must see event"
  end

  test "non participant can see events page" do
    get :index
    assert_response :success, "Response must be success"
    assert_not_nil assigns(:events), "Events must be assigned"
    assert_equal 0, assigns(:events).length, "Non participant must not see event"
  end

  test "organizer can see new page" do
    sign_in @organizer
  	get :new
  	assert_response :success, "Response must be success"
    assert_template :new, "New page must be rendered"
  	assert_not_nil assigns(:event), "Event must be assigned"
  end

  test "participant can see new page" do
    sign_in @user1
    get :new
    assert_response :success, "Response must be success"
    assert_template :new, "New page must be rendered"
    assert_not_nil assigns(:event), "Event must be assigned"
  end

  test "non participant can see new page" do
    sign_in @non_participant_user
    get :new
    assert_response :success, "Response must be success"
    assert_template :new, "New page must be rendered"
    assert_not_nil assigns(:event), "Event must be assigned"
  end

  test "user can create valid event and becomes participant" do
  	test_event = {name: "Test event", from_date: Date.current, end_date: Date.current+3, description: "Test description", 
  		event_currency: "EUR", organizer_id: @non_participant_user.id}
  	assert_difference('Event.count', 1, "Event must be created") do
  		post :create, event: test_event
  	end
  	assert_response :redirect, "Response must be redirect"
  	assert_equal "Event created.", flash[:notice], "Flash[:notice] must state that event was created"
    assert_not_nil assigns(:event), "Event must be assigned"
  	assert_redirected_to events_path, "Redirect must be events_path"
  	assert_includes assigns(:event).users, @non_participant_user, "User must be participant of event"
    assert_equal @non_participant_user.id, assigns(:event).organizer_id, "Event organizer must be the event creator"
  end

  test "user tries to create event with invalid data and is sent back to new page" do
  	test_event = {name: nil}
  	post :create, event: test_event
  	assert_response :success, "Response must be success"
  	assert_template :new, "New page must be rendered"
  	assert_equal "Event is invalid. Please correct.", flash[:notice]
  end

  test "organizer can edit event" do
  	sign_in @organizer
  	get :edit, id: @event.id
  	assert_response :success, "Response must be success"
  	assert_template :edit, "Edit page must be rendered"
  	assert assigns(:event), "Event must be assigned"
  end

  test "participant cannot edit event" do
  	sign_in @user1
  	get :edit, id: @event.id
  	assert_response :forbidden, "Response must be forbidden"
  end

  test "non participant cannot edit event" do
  	get :edit, id: @event.id
  	assert_response :forbidden, "Response must be forbidden"
  end

  test "organizer can update event" do
  	sign_in @organizer
   	test_event = {name: "Randers", from_date: Date.new(2012, 11, 2), 
			end_date: Date.new(2012, 11, 4), description: "Come Malaka event in a different country", 
			event_currency: "EUR", organizer_id: @organizer.id}
  	put :update, id: @event.id, event: test_event
  	assert_response :redirect, "Response must be redirect"
  	assert_redirected_to events_path, "Redirect must be events_path"
  	assert_equal "Event updated.", flash[:notice], "Flash[:notice] must state that event was updated"
  end

  test "organizer tries to update event with invalid data and is sent back to edit page" do
  	sign_in @organizer
   	test_event = {name: nil}
  	put :update, id: @event.id, event: test_event
  	assert_response :success, "Response must be success"
  	assert_template :edit, "Edit page must be rendered"
  	assert_equal "Event cannot be updated with invalid data. Please correct.", flash[:notice], "Flash[:notice] must state that event is invalid"
  end

  test "participant cannot update event" do
  	sign_in @user1
    test_event = {name: "Randers", from_date: Date.new(2012, 11, 2), 
			end_date: Date.new(2012, 11, 4), description: "Come Malaka event in a different country", 
			event_currency: "EUR", organizer_id: @organizer.id}
  	put :update, id: @event.id, event: test_event
  	assert_response :forbidden, "Response must be forbidden"
  end

  test "non participant cannot update event" do
    test_event = {name: "Randers", from_date: Date.new(2012, 11, 2), 
			end_date: Date.new(2012, 11, 4), description: "Come Malaka event in a different country", 
			event_currency: "EUR", organizer_id: @organizer.id}
  	put :update, id: @event.id, event: test_event
  	assert_response :forbidden, "Response must be forbidden"
  end

  test "organizer can delete event" do
  	sign_in @organizer
  	@event.items = [] #make event deletable by removing its items
  	assert_difference('Event.count', -1, "Event must be deleted") do
	  	delete :destroy, id: @event.id
  	end	
  	assert_response :redirect, "Response must be redirect"
  	assert_redirected_to events_path, "Redirect must be events_path"
  	assert_equal "Event deleted.", flash[:notice]
  end

  test "organizer must fail to delete an event that contains items" do
  	sign_in @organizer
  	assert_no_difference('Event.count', "Event must not be deleted") do
	  	delete :destroy, id: @event.id
  	end	
  	assert_response :redirect, "Response must be redirect"
  	assert_redirected_to events_path, "Redirect must be events_path"
  	assert_equal "Event cannot be deleted. Posted items exist.", flash[:notice], "Flash[:notice] must state that event cannot be deleted due to existing items"
  end

  test "participant cannot delete event" do
  	sign_in @user1
  	@event.items = [] #make event deletable by removing its items
    assert_no_difference('Event.count', "Event must not be deleted") do
      delete :destroy, id: @event.id
    end
    assert_response :forbidden, "Response must be forbidden"
  end

  test "non participant cannot delete event" do
  	@event.items = [] #make event deletable by removing its items
    assert_no_difference('Event.count', "Event must not be deleted") do
      delete :destroy, id: @event.id
    end
    assert_response :forbidden, "Response must be forbidden"
  end

  test "organizer can display event" do
  	sign_in @organizer
  	get :show, id: @event.id
  	assert_response :success, "Response must be success"
  	assert assigns(:event), "Event must be assigned"
  end

  test "event participant can display event" do
  	sign_in @user1
  	get :show, id: @event.id
  	assert_response :success, "Response must be success"
  	assert assigns(:event), "Event must be assigned"
  end

  test "non participant cannot display event" do
  	get :show, id: @event.id
  	assert_response :forbidden, "Response must be forbidden"
  end

  test "organizer can see all event items" do
  	sign_in @organizer
  	get :event_all_items, event_id: @event.id
  	assert_response :success, "Response must be success"
  	assert assigns(:items), "Items must be assigned"
  end

  test "participant can see all event items" do
  	sign_in @user1
  	get :event_all_items, event_id: @event.id
  	assert_response :success, "Response must be success"
  	assert assigns(:items), "Items must be assigned"
  end

  test "non participant cannot see all event items" do
  	get :event_all_items, event_id: @event.id
  	assert_response :forbidden, "Response must be forbidden"
  	assert_nil assigns(:items), "Items must not be assigned"
  end

  test "organizer can see expense report" do
  	sign_in @organizer
  	get :expense_report, event_id: @event.id
  	assert_response :success, "Response must be success"
  	assert assigns(:event), "Event must be assigned"
  	assert assigns(:participants), "Participants must be assigned"
  	assert assigns(:items), "Items must be assigned"
  end

  test "participant can see expense report" do
  	sign_in @user1
  	get :expense_report, event_id: @event.id
  	assert_response :success, "Response must be success"
  	assert assigns(:event), "Event must be assigned"
  	assert assigns(:participants), "Participants must be assigned"
  	assert assigns(:items), "Items must be assigned"  end

  test "non participant cannot see expense report" do
  	get :expense_report, event_id: @event.id
  	assert_response :forbidden, "Response must be forbidden"
  	assert_nil assigns(:participants), "Participants must not be assigned"
  	assert_nil assigns(:items), "Items must not be assigned"
  end

  test "organizer can see Who owes you? details" do
    sign_in @organizer
    get :who_owes_you, event_id: @event.id
    assert_response :success, "Response must be success"
    assert assigns(:event), "Event must be assigned"
    assert_not_empty assigns(:total_amounts), "Total amount must not be empty"
    assert_not_empty assigns(:item_lists), "Item lists must not be empty"
  end

  test "participant (payer) can see Who owes you? details" do
    sign_in @user4
    get :who_owes_you, event_id: @event.id
    assert_response :success, "Response must be success"
    assert assigns(:event), "Event must be assigned"
    assert_not_empty assigns(:total_amounts), "Total amount must not be empty"
    assert_not_empty assigns(:item_lists), "Item lists must not be empty"
  end

  test "participant (non payer) can see Who owes you? details" do
    sign_in @user1
    get :who_owes_you, event_id: @event.id
    assert_response :success, "Response must be success"
    assert assigns(:event), "Event must be assigned"
    assert_empty assigns(:total_amounts), "Total amount must be empty"
    assert_empty assigns(:item_lists), "Item lists must be empty"
  end

  test "non participant cannot see Who owes you? details" do
    sign_in @non_participant_user
    get :who_owes_you, event_id: @event.id
    assert_response :forbidden, "Response must be forbidden"
    assert_nil assigns(:total_amounts), "Total amounts must be emtpy"
    assert_nil assigns(:item_lists), "Item lists must be empty"
  end

end
