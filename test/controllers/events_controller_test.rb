require 'test_helper'

class EventsControllerTest < ActionController::TestCase
  include ApplicationHelper

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
    assert_not_empty assigns(:total_amounts), "Total amounts must not be empty"
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
    get :who_owes_you, event_id: @event.id
    assert_response :forbidden, "Response must be forbidden"
    assert_nil assigns(:total_amounts), "Total amounts must be emtpy"
    assert_nil assigns(:item_lists), "Item lists must be empty"
  end

  test "organizer can see you owe whom? details" do
    sign_in @organizer
    get :you_owe_whom, event_id: @event.id
    assert_response :success, "Response must be success"
    assert assigns(:event), "Event must be assigned"
    assert_not_empty assigns(:total_amounts), "Total amounts must not be empty"
    assert_not_empty assigns(:item_lists), "Item lists must not be empty"
  end

  test "participant (payer and beneficiary) can see you owe whom? details" do
    sign_in @user5
    get :you_owe_whom, event_id: @event.id
    assert_response :success, "Response must be success"
    assert assigns(:event), "Event must be assigned"
    assert_not_empty assigns(:total_amounts), "Total amounts must not be empty"
    assert_not_empty assigns(:item_lists), "Item lists must not be empty"
  end

  test "non participant cannot see you owe whom? details" do
    get :you_owe_whom, event_id: @event.id
    assert_response :forbidden, "Response must be forbidden"
    assert_nil assigns(:total_amounts), "Total amounts must be emtpy"
    assert_nil assigns(:item_lists), "Item lists must be empty"
  end

  # Test the views/pages
  
  test "index page with no events" do
    @event = nil
    get :index
    assert_select "title", "Your events"
    assert_select "body a", "Create new event"
    assert_select "body a:match('href', ?)", new_event_path
    assert_select "p", "You don't have any events."
  end

  test "organizer's index page with events" do
    sign_in @organizer
    get :index
    assert_select "div.table-selector table.tablesaw[align=center]" 
    assert_select "div.table-selector table.tablesaw[data-tablesaw-mode=stack]"
    assert_select "div.table-selector table.tablesaw caption", "Your events"
    head = "div.table-selector table.tablesaw thead tr th"
    assert_select head, "Event"
    assert_select head, "Description"
    assert_select head, "Start date"
    assert_select head, "End date"
    assert_select head, "Event currency"
    assert_select head, "Organizer"
    assert_select head, "Participants*"
    assert_select "div.table-selector table.tablesaw tfoot tr[data-tablesaw-no-labels] td[colspan='7']", "* Hover or click over the text for details"
    assert_select "div.table-selector table.tablesaw tbody tr td a.dropdown[data-dropdown=action#{@event.id}]", @event.name
    ul = "div.table-selector table.tablesaw tbody tr td ul#action#{@event.id}"
    assert_select ul + ".f-dropdown[data-dropdown-content]"
    assert_select ul + " li a[href='#{edit_event_path(@event)}']", 'Edit'
    assert_select ul + " li a[href='#{event_path(@event)}'][data-confirm][data-method=delete]", 'Delete'
    assert_select ul + " li a[href='#{event_path(@event)}']", 'View details'
    assert_select ul + " li a[href='#{invite_to_event_path(@event)}']", 'Invite to event'
    assert_select ul + " li a[href='#{event_all_items_path(@event)}']", 'All items'
    assert_select ul + " li a[href='#{event_items_path(@event)}']", 'Your items'
    assert_select ul + " li a[href='#{expense_report_path(@event)}']", 'Expense Report'
    tbody_td = "div.table-selector table.tablesaw tbody tr td"
    assert_select tbody_td, @event.description
    assert_select tbody_td, @event.from_date.strftime('%d %b %Y')
    assert_select tbody_td, @event.end_date.strftime('%d %b %Y')
    assert_select tbody_td + " span.has-tip[data-tooltip][title=?]", Money::Currency.new(@event.event_currency).name, {text: @event.event_currency.upcase}
    assert_select tbody_td, @event.organizer.short_name
    user_names = @event.users.map { |u| u.short_name }.join(", ") 
    assert_select tbody_td + " span.has-tip[data-tooltip][title='#{user_names}']", {text: @event.users.count.to_s}
  end

  test "participant's index page with events" do
    sign_in @user1
    get :index
    assert_select "div.table-selector table.tablesaw[align=center]" 
    assert_select "div.table-selector table.tablesaw[data-tablesaw-mode=stack]"
    assert_select "div.table-selector table.tablesaw caption", "Your events"
    head = "div.table-selector table.tablesaw thead tr th"
    assert_select head, "Event"
    assert_select head, "Description"
    assert_select head, "Start date"
    assert_select head, "End date"
    assert_select head, "Event currency"
    assert_select head, "Organizer"
    assert_select head, "Participants*"
    assert_select "div.table-selector table.tablesaw tfoot tr[data-tablesaw-no-labels] td[colspan='7']", "* Hover or click over the text for details"
    assert_select "div.table-selector table.tablesaw tbody tr td a.dropdown[data-dropdown=action#{@event.id}]", @event.name
    ul = "div.table-selector table.tablesaw tbody tr td ul#action#{@event.id}"
    assert_select ul + ".f-dropdown[data-dropdown-content]"
    assert_select ul + " li a[href='#{edit_event_path(@event)}']", false
    assert_select ul + " li a[href='#{event_path(@event)}'][data-confirm][data-method=delete]", false
    assert_select ul + " li a[href='#{event_path(@event)}']", 'View details'
    assert_select ul + " li a[href='#{invite_to_event_path(@event)}']", false
    assert_select ul + " li a[href='#{event_all_items_path(@event)}']", 'All items'
    assert_select ul + " li a[href='#{event_items_path(@event)}']", 'Your items'
    assert_select ul + " li a[href='#{expense_report_path(@event)}']", 'Expense Report'
    tbody_td = "div.table-selector table.tablesaw tbody tr td"
    assert_select tbody_td, @event.description
    assert_select tbody_td, @event.from_date.strftime('%d %b %Y')
    assert_select tbody_td, @event.end_date.strftime('%d %b %Y')
    assert_select tbody_td + " span.has-tip[data-tooltip][title=?]", Money::Currency.new(@event.event_currency).name, {text: @event.event_currency.upcase}
    assert_select tbody_td, @event.organizer.short_name
    user_names = @event.users.map { |u| u.short_name }.join(", ") 
    assert_select tbody_td + " span.has-tip[data-tooltip][title='#{user_names}']", {text: @event.users.count.to_s}
  end

  test "new event page" do
    get :new
    assert_select "title", "Create new event"
    assert_select "p a[href=?]", events_path, {text: "Back to events page"}
    #Test form and Foundation Abide and Grid
    assert_select "form[data-abide=true]"
    assert_select "form[novalidate=novalidate]"
    assert_select "form div.row div.small-12.medium-8.large-6.columns.small-centered fieldset" do
      assert_select "legend", "Create new event"
      
      label = "div.field.small-12.medium-4.large-4.columns.end label"
      input = "div.small-12.medium-8.large-8.columns.end input"
      error = "div.small-12.medium-8.large-8.columns.end small.error"

      assert_select label, "Name"
      assert_select input + "#event_name[required=?]", "required" 
      assert_select error, "Please name the event."
      assert_select label, "Description"
      assert_select input + "#event_description[required=?]", "required" 
      assert_select error, "Please describe the event."
      assert_select label, "Start date"
      assert_select input + "#event_from_date[required=?]", "required" 
      assert_select input + "#event_from_date[size=?]", "10" 
      assert_select error, "Please choose a start date for the event."
      assert_select label, "End date"
      assert_select input + "#event_end_date[required=?]", "required" 
      assert_select input + "#event_end_date[size=?]", "10" 
      assert_select error, "Please choose an end date for the event."
      assert_select label, "Event currency"
      assert_select "div.small-12.medium-8.large-8.columns.end select#event_event_currency" do
        assert_select "#event_event_currency[required=?]", "required"
        assert_select "option[value=?]", "", {text: "Select event currency"}
        Money::Currency.all.each do |currency|
          assert_select "option[value=?]", currency.id.to_s, {text: currency.iso_code.to_s}
        end
      end
      assert_select error, "Please choose an event currency."
      assert_select label, "Organizer"
      assert_select "div.small-12.medium-8.large-8.columns.end select#event_organizer_id" do
        assert_select "option[value=?]", @non_participant_user.id.to_s
        assert_select "option[selected=selected]", @non_participant_user.name
      end
      assert_select "div.actions.small-12.medium-8.large-8.columns.end input[value=?]", "Create event"
    end
  end

  test "show event details page" do
    sign_in @organizer
    get :show, id: @event.id
    assert_select "title", "Details about " + @event.name
    assert_select "p a[href=?]", events_path, {text: "Back to events page"}
    assert_select "form div.row div.small-12.medium-8.large-6.columns.small-centered fieldset" do
      assert_select "[disabled]"
      assert_select "legend", "View event details"
      assert_select "div.row", 7
      
      label = "div.row div.field.small-12.medium-4.large-4.columns.end label"
      input = "div.row div.small-12.medium-8.large-8.columns.end input"

      assert_select label, "Name" 
      assert_select input + "#event_name[value=?]", @event.name
      assert_select label, "Description"
      assert_select input + "#event_description[value=?]", @event.description
      assert_select label, "Start date"
      assert_select input + "#event_from_date[value=?]", @event.from_date.to_s
      assert_select label, "End date"
      assert_select input + "#event_end_date[value=?]", @event.end_date.to_s
      assert_select label, "Event currency"
      assert_select input + "#event_event_currency[value=?]", @event.event_currency
      assert_select label, "Organizer"
      assert_select input + "#dummy[value=?]", @event.organizer.name
      assert_select label, "Participants"
      @event.users.each do |user|
        assert_select "div.row div.small-12.medium-8.large-8.columns.end label[for=?]", "event_user_ids_" + user.id.to_s, {text: user.name}
        assert_select "div.row div.small-12.medium-8.large-8.columns.end label input#event_user_ids_" + user.id.to_s + "[checked=checked][value=?]", user.id.to_s 
      end
    end
  end
#When items are posted the event currency cannot be modified
test "edit event page (with posted items)" do
    sign_in @organizer
    get :edit, id: @event.id
    assert_select "title", "Edit " + @event.name + " event"
    assert_select "p a[href=?]", events_path, {text: "Back to events page"}
    #Test form and Foundation Abide and Grid
    assert_select "form[data-abide=true]"
    assert_select "form[novalidate=novalidate]"
    assert_select "form div.row div.small-12.medium-8.large-6.columns.small-centered fieldset" do
      assert_select "legend", "Edit event"
      
      label = "div.field.small-12.medium-4.large-4.columns.end label"
      input = "div.small-12.medium-8.large-8.columns.end input"
      error = "div.small-12.medium-8.large-8.columns.end small.error"

      assert_select label, "Name"
      assert_select input + "#event_name[required=?]", "required" 
      assert_select error, "Please name the event."
      assert_select label, "Description"
      assert_select input + "#event_description[required=?]", "required" 
      assert_select error, "Please describe the event."
      assert_select label, "Start date"
      assert_select input + "#event_from_date[required=?]", "required" 
      assert_select input + "#event_from_date[size=?]", "10" 
      assert_select error, "Please choose a start date for the event."
      assert_select label, "End date"
      assert_select input + "#event_end_date[required=?]", "required" 
      assert_select input + "#event_end_date[size=?]", "10" 
      assert_select error, "Please choose an end date for the event."
      assert_select label, "Event currency"
      assert_select input + "#event_event_currency[value=?][disabled=disabled]", @event.event_currency.to_s 
      assert_select "div.actions.small-12.medium-8.large-8.columns.end input[value=?]", "Save event"
    end
  end

  #when there are no posted items the event currency can be modified
test "edit event page (without posted items)" do
    sign_in @organizer
    @event.items = nil
    get :edit, id: @event.id
    assert_select "title", "Edit " + @event.name + " event"
    assert_select "p a[href=?]", events_path, {text: "Back to events page"}
    #Test form and Foundation Abide and Grid
    assert_select "form[data-abide=true]"
    assert_select "form[novalidate=novalidate]"
    assert_select "form div.row div.small-12.medium-8.large-6.columns.small-centered fieldset" do
      assert_select "legend", "Edit event"
      
      label = "div.field.small-12.medium-4.large-4.columns.end label"
      input = "div.small-12.medium-8.large-8.columns.end input"
      error = "div.small-12.medium-8.large-8.columns.end small.error"

      assert_select label, "Name"
      assert_select input + "#event_name[required=?]", "required" 
      assert_select error, "Please name the event."
      assert_select label, "Description"
      assert_select input + "#event_description[required=?]", "required" 
      assert_select error, "Please describe the event."
      assert_select label, "Start date"
      assert_select input + "#event_from_date[required=?]", "required" 
      assert_select input + "#event_from_date[size=?]", "10" 
      assert_select error, "Please choose a start date for the event."
      assert_select label, "End date"
      assert_select input + "#event_end_date[required=?]", "required" 
      assert_select input + "#event_end_date[size=?]", "10" 
      assert_select error, "Please choose an end date for the event."
      assert_select label, "Event currency"
      assert_select "div.small-12.medium-8.large-8.columns.end select#event_event_currency" do
        Money::Currency.all.each do |currency|
          assert_select "option[value=?]", currency.id.to_s, {text: currency.iso_code.to_s}
        end
      end
      assert_select "div.actions.small-12.medium-8.large-8.columns.end input[value=?]", "Save event"
    end
  end

  test "expense report page" do
    sign_in @organizer
    get :expense_report, event_id: @event.id
    assert_select "title", "Expense report for " + @event.name + " event"
    assert_select "a[href=?]", events_path, {text: "Back to events page"}
    assert_select "a[href=?]", who_owes_you_path(@event), {text: "Who owes you?"}
    assert_select "a[href=?]", you_owe_whom_path(@event), {text: "You owe whom?"}
    #Test table and Foundation Grid
    table = "div.row div.small-12.columns.small-centered.table-selector table.tablesaw"
    assert_select table + "[role=grid][data-tablesaw-mode=stack]" 
    assert_select table + " caption", /Expense Summary\*/
    assert_select table + " caption span.has-tip[data-tooltip][title=?]", Money::Currency.new(@event.event_currency).name, {text: "(base currency is #{@event.event_currency.upcase})"}
    head = table + " thead tr th"
    assert_select head, "Participant"
    assert_select head, "Total Paid"
    assert_select head, "Total Benefited"
    assert_select head, "Balance"
    assert_select table + " tfoot tr[data-tablesaw-no-labels] td[colspan='4']", "*Amounts are rounded for display"
    body = table + " tbody tr td"
    @event.users.each do |participant|
      assert_select body, participant.short_name
      assert_select body, money_format(@event.total_expenses_amount_for(participant), @event.event_currency)
      assert_select body, money_format(@event.total_benefited_amount_for(participant), @event.event_currency)
      assert_select body, money_format(@event.balance_for(participant), @event.event_currency)
    end 
  end

  test "event's all items page (with items)" do
    sign_in @organizer
    get :event_all_items, event_id: @event.id
    assert_select "title", "All items of " + @event.name + " event"
    assert_select "p a[href=?]", events_path, {text: "Back to events page"}
    assert_select "p a[href=?]", new_event_item_path(@event.id), {text: "Create new item"}
    table = "div.table-selector table.tablesaw[role=grid][data-tablesaw-mode=stack]"
    assert_select table + " caption", "All items of Randers event"
    head = table + " thead tr th"
    assert_select head, "Name"
    assert_select head, "Date"
    assert_select head, "Description"
    assert_select head, "Base amount*"
    assert_select head, "Exchange rate"
    assert_select head, "Foreign amount*"
    assert_select head, "Payer"
    assert_select head, "Beneficiaries**"
    assert_select head, "Cost per beneficiary"
    foot = table + " tfoot tr[data-tablesaw-no-labels] td[colspan='9']"
    assert_select foot, /^\* Amounts are rounded for display\n\n\*\* Hover or click over the text for details$/
    body = table + " tbody tr td"
    @event.items.each do |item|
      assert_select body + " a.dropdown[data-dropdown=?]", "action" + item.id.to_s, {text: item.name}
      li = body + " ul.f-dropdown#action#{item.id.to_s}[data-dropdown-content] li"
      assert_select li + " a[href=?]", item_path(item), "View details"
      if item.payer == @organizer then
        assert_select li + " a[href=?]", edit_item_path(item), "Edit"
        assert_select li + " a[href=?][data-confirm][data-method=delete]", item_path(item), "Delete"
      end
      assert_select body, item.value_date.strftime('%d %b %Y')
      assert_select body, item.description
      assert_select body + " span.has-tip[data-tooltip][title=?]", Money::Currency.new(item.base_currency).name, money_format(item.base_amount, item.base_currency)
      assert_select body, item.exchange_rate.to_s
      assert_select body + " span.has-tip[data-tooltip][title=?]", Money::Currency.new(item.foreign_currency).name, money_format(item.foreign_amount, item.foreign_currency)
      assert_select body, item.payer.short_name
      assert_select body + " span.has-tip[data-tooltip][title=?]", item.beneficiaries.map{ |b| b.short_name }.join(', '), item.beneficiaries.count.to_s
      assert_select body, money_format(item.cost_per_beneficiary, item.base_currency)
    end
  end

  test "event's all items page (without items)" do
    @event.items = []
    sign_in @organizer
    get :event_all_items, event_id: @event.id
    assert_select "title", "All items of " + @event.name + " event"
    assert_select "p a[href=?]", events_path, {text: "Back to events page"}
    assert_select "p a[href=?]", new_event_item_path(@event.id), {text: "Create new item"}
    assert_select "p", "You don't have any items."
  end

  test "who owes you page" do
    sign_in @organizer
    get :who_owes_you, event_id: @event.id
    assert_select "title", "Who owes you?"
    assert_select "a[href=?]", expense_report_path(@event), {text: "Back to expense summary"}

    ul_header = "ul[style='list-style-type:none'] li u"
    ul_line = "ul[style='list-style-type:none'] ul li"
    date1 = @event.from_date.strftime('%d %b %Y')
    date2 = (@event.from_date+1).strftime('%d %b %Y')

    assert_select ul_header, "Elyasin owes you €124.00 in total"
    assert_select ul_line, "Elyasin owes you €40.22 on the " + date1 + " for item Food (Food)"
    assert_select ul_line, "Elyasin owes you €11.17 on the " + date1 + " for item Gas (Gas)"
    assert_select ul_line, "Elyasin owes you €11.17 on the " + date1 + " for item Drinks (Drinks)"
    assert_select ul_line, "Elyasin owes you €36.86 on the " + date1 + " for item Night out (Night out & Misc)"
    assert_select ul_line, "Elyasin owes you €24.58 on the " + date2 + " for item Night out (Night out & Misc)"
    assert_select ul_header, "Juan owes you €124.00 in total"
    assert_select ul_line, "Juan owes you €40.22 on the " + date1 + " for item Food (Food)"
    assert_select ul_line, "Juan owes you €11.17 on the " + date1 + " for item Gas (Gas)"
    assert_select ul_line, "Juan owes you €11.17 on the " + date1 + " for item Drinks (Drinks)"
    assert_select ul_line, "Juan owes you €36.86 on the " + date1 + " for item Night out (Night out & Misc)"
    assert_select ul_line, "Juan owes you €24.58 on the " + date2 + " for item Night out (Night out & Misc)"
    assert_select ul_header, "Neal owes you €87.14 in total"
    assert_select ul_line, "Neal owes you €40.22 on the " + date1 + " for item Food (Food)"
    assert_select ul_line, "Neal owes you €11.17 on the " + date1 + " for item Gas (Gas)"
    assert_select ul_line, "Neal owes you €11.17 on the " + date1 + " for item Drinks (Drinks)"
    assert_select ul_line, "Neal owes you €24.58 on the " + date2 + " for item Night out (Night out & Misc)"    
    assert_select ul_header, "Nuno owes you €124.00 in total"
    assert_select ul_line, "Nuno owes you €40.22 on the " + date1 + " for item Food (Food)"
    assert_select ul_line, "Nuno owes you €11.17 on the " + date1 + " for item Gas (Gas)"
    assert_select ul_line, "Nuno owes you €11.17 on the " + date1 + " for item Drinks (Drinks)"
    assert_select ul_line, "Nuno owes you €36.86 on the " + date1 + " for item Night out (Night out & Misc)"
    assert_select ul_line, "Nuno owes you €24.58 on the " + date2 + " for item Night out (Night out & Misc)"
    assert_select ul_header, "Theo owes you €87.14 in total"
    assert_select ul_line, "Theo owes you €40.22 on the " + date1 + " for item Food (Food)"
    assert_select ul_line, "Theo owes you €11.17 on the " + date1 + " for item Gas (Gas)"
    assert_select ul_line, "Theo owes you €11.17 on the " + date1 + " for item Drinks (Drinks)"
    assert_select ul_line, "Theo owes you €24.58 on the " + date2 + " for item Night out (Night out & Misc)"
  end


  test "you owe whom page" do
    sign_in @organizer
    get :you_owe_whom, event_id: @event.id
    assert_select "title", "You owe whom?"
    assert_select "a[href=?]", expense_report_path(@event), {text: "Back to expense summary"}

    ul_header = "ul[style='list-style-type:none'] li u"
    ul_line = "ul[style='list-style-type:none'] ul li"
    date2 = (@event.from_date+1).strftime('%d %b %Y')

    assert_select ul_header, "You owe Juan €1.79 in total"
    assert_select ul_line, "You owe Juan €1.79 on the " + date2 + " for item Taxi (Taxi)"
  end

end
