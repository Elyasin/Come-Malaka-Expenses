require 'test_helper'
require 'webmock/minitest'
require 'open-uri'

class ItemsControllerTest < ActionController::TestCase
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

  test "unauthenticated user for any item controller action must be redirected to sign in page" do

  	sign_out @non_participant_user

    get :index, event_id: @event.id
    assert_response :redirect, "Response must be redirect"
    assert_redirected_to new_user_session_path, "Redirect must be new_user_session_path"

    get :show, id: @item1.id
    assert_response :redirect, "Response must be redirect"
    assert_redirected_to new_user_session_path, "Redirect must be new_user_session_path"

    get :edit, id: @item1.id
    assert_response :redirect, "Response must be redirect"
    assert_redirected_to new_user_session_path, "Redirect must be new_user_session_path"

    assert_no_difference('Item.count', "Item must not be created") do
      put :update, id: @item1.id
    end
    assert_response :redirect, "Response must be redirect"
    assert_redirected_to new_user_session_path, "Redirect must be new_user_session_path"

    get :new, event_id: @event.id
    assert_response :redirect, "Response must be redirect"
    assert_redirected_to new_user_session_path, "Redirect must be new_user_session_path"

    assert_no_difference('Item.count', "Item must not be created") do
      post :create, event_id: @event.id
    end
    assert_response :redirect, "Response must be redirect"
    assert_redirected_to new_user_session_path, "Redirect must be new_user_session_path"

    assert_no_difference('Item.count', "Item must not be created") do
      delete :destroy, id: @item1.id
    end
    assert_response :redirect, "Response must be redirect"
    assert_redirected_to new_user_session_path, "Redirect must be new_user_session_path"
  end

  test "organizer can see items page" do
  	sign_in @organizer
  	get :index, event_id: @event.id
  	assert_response :success, "Response must be success"
  	assert_not_nil assigns(:items), "Items must be assigned"
  end

  test "participant can see items page" do
  	sign_in @user1
  	get :index, event_id: @event.id
  	assert_response :success, "Response must be success"
  	assert_not_nil assigns(:items), "Items must be assigned"
  end

  test "non participant cannot see items page" do
  	get :index, event_id: @event.id
  	assert_response :forbidden, "Response must be forbidden"
  end

  test "organizer can see new page" do
  	sign_in @organizer
  	get :new, event_id: @event.id
  	assert_response :success, "Response must be success"
  	assert_not_nil assigns(:item), "Item must be assigned"
  end

  test "participant can see new page" do
  	sign_in @user1
  	get :new, event_id: @event.id
  	assert_response :success, "Response must be success"
  	assert_not_nil assigns(:item), "Item must be assigned"
  end

  test "non participant cannot see new page" do
   	get :new, event_id: @event.id
  	assert_response :forbidden, "Response must be forbidden"
  end

  test "organizer can create valid item with manual exchange currency" do
  	sign_in @organizer
    new_item = { name: "New item", value_date: @event.from_date, description: "New description", 
      base_amount: 10, base_currency: "eur", exchange_rate: 1,  
      foreign_amount: 10, foreign_currency: "eur", payer_id: @organizer.id, 
      beneficiary_ids: [@organizer.id, @user1.id, @user3.id, @user4.id] }
    assert_difference('Item.count', 1, "Item must be created") do
      post :create, event_id: @event.id, item: new_item
    end
    assert_response :redirect, "Response must be redirect"
    assert_redirected_to item_path(assigns(:item)), "Redirect must be event_items_path"
    assert_equal "Item created.", flash[:notice], "Flash[:notice] must state that item was created"
    assert_nil flash[:alert], "Flash[:alert] must be empty"
    assert_equal @organizer, assigns(:item).payer, "Item owner must be the payer"
    assigns(:item).event.users.each do |participant|
      assert participant.has_role?(:event_participant, assigns(:item)), "Event participants must have event participant role for items"
    end
    assert_empty assigns(:item).errors, "Item must not have errors"
  end

  test "organizer can create valid item with automatic exchange currency" do
    sign_in @organizer
    new_item = { name: "New item", value_date: @event.from_date, description: "New description", 
      base_amount: 10, base_currency: "eur", exchange_rate: "",  
      foreign_amount: 10, foreign_currency: "eur", payer_id: @organizer.id, 
      beneficiary_ids: [@organizer.id, @user1.id, @user3.id, @user4.id] }
      stub_request(:get, "http://devel.farebookings.com/api/curconversor/EUR/EUR/1/json").to_return(:status => 200, :body => '{"EUR": 1}')
    assert_difference('Item.count', 1, "Item must not be created") do
      post :create, event_id: @event.id, item: new_item
    end
    assert_response :redirect, "Response must be redirect"
    assert_redirected_to item_path(assigns(:item))
    assert_equal "Item created.", flash[:notice], "Flash[:notice] must state that item was created"
    assert_equal "Exchange rate updated to #{assigns(:item).exchange_rate}.", flash[:alert], "Flash[:alert] must state that exchange rate changed"
    assert_equal @organizer, assigns(:item).payer, "Item owner must be the payer"
    assigns(:item).event.users.each do |participant|
      assert participant.has_role?(:event_participant, assigns(:item)), "Event participants must have event participant role for items"
    end
    assert_empty assigns(:item).errors, "Item must not have errors"
  end

  test "organizer cannot create invalid item" do
  	sign_in @organizer
    new_item = { name: nil, value_date: @event.from_date, description: "New description", 
      base_amount: 10, base_currency: "eur", exchange_rate: 1,  
      foreign_amount: 10, foreign_currency: "eur", payer_id: @organizer.id, 
      beneficiary_ids: [@organizer.id, @user1.id, @user3.id, @user4.id] }
    assert_no_difference('Item.count', message = "Item must not be created") do
      post :create, event_id: @event.id, item: new_item
    end
    assert_response :success, "Response must be success"
    assert_template :new, "New page must be rendered"
    assert_equal "Item is invalid. Please correct.", flash[:notice], "Flash[:notice] state that item is invalid"
    assert_nil flash[:alert], "Flash[:alert] must be empty"
    assert_not_empty assigns(:item).errors, "Item errors must not be empty"
    assert_select "form div.row div.small-12.medium-8.large-6.columns.small-centered fieldset div.field.small-12.medium-4.large-4.columns.end .field_with_errors"
  end

  test "organizer cannot create invalid item (special case: automatic exchange rate update fails)" do
    sign_in @organizer
    new_item = { name: "New item", value_date: @event.from_date, description: "New description", 
      base_amount: 10, base_currency: "eur", exchange_rate: "",  
      foreign_amount: 10, foreign_currency: "eur", payer_id: @organizer.id, 
      beneficiary_ids: [@organizer.id, @user1.id, @user3.id, @user4.id] }
    stub_request(:get, "http://devel.farebookings.com/api/curconversor/EUR/EUR/1/json").to_raise(OpenURI::HTTPError.new(nil, ""))
    assert_no_difference('Item.count', "Item must not be created") do
      post :create, event_id: @event.id, item: new_item
    end
    assert_response :success, "Response must be success"
    assert_template :new, "New page must be rendered"
    assert_equal "Item is invalid. Please correct.", flash[:notice], "Flash[:notice] state that item is invalid"
    assert_nil flash[:alert], "Flash[:alert] must be empty"
    assert_not_empty assigns(:item).errors, "Item errors must not be empty"
    assert_select "form div.row div.small-12.medium-8.large-6.columns.small-centered fieldset div.field.small-12.medium-4.large-4.columns.end .field_with_errors"
  end

  test "participant can create valid item with manual exchange currency" do
    sign_in @user1
    new_item = { name: "New item", value_date: @event.from_date, description: "New description", 
      base_amount: 10, base_currency: "eur", exchange_rate: 1,  
      foreign_amount: 10, foreign_currency: "eur", payer_id: @user1.id, 
      beneficiary_ids: [@organizer.id, @user1.id, @user3.id, @user4.id] }
    assert_difference('Item.count', 1, "Item must not be created") do
      post :create, event_id: @event.id, item: new_item
    end
    assert_response :redirect, "Response must be redirect"
    assert_redirected_to item_path(assigns(:item)), "Redirect must be event_items_path"
    assert_equal "Item created.", flash[:notice], "Flash[:notice] must state that item was created"
    assert_nil flash[:alert], "Flash[:alert] must be empty"
    assert_equal @user1, assigns(:item).payer, "Item owner must be the payer"
    assigns(:item).event.users.each do |participant|
      assert participant.has_role?(:event_participant, assigns(:item)), "Event participants must have event participant role for items"
    end
    assert_empty assigns(:item).errors, "Item must not have errors"
  end

  test "participant can create valid item with automatic exchange currency" do
    sign_in @user1
    new_item = { name: "New item", value_date: @event.from_date, description: "New description", 
      base_amount: 10, base_currency: "eur", exchange_rate: "",  
      foreign_amount: 10, foreign_currency: "eur", payer_id: @user1.id, 
      beneficiary_ids: [@organizer.id, @user1.id, @user3.id, @user4.id] }
      stub_request(:get, "http://devel.farebookings.com/api/curconversor/EUR/EUR/1/json").to_return(:status => 200, :body => '{"EUR": 1}')
    assert_difference('Item.count', 1, "Item must not be created") do
      post :create, event_id: @event.id, item: new_item
    end
    assert_response :redirect, "Response must be redirect"
    assert_redirected_to item_path(assigns(:item))
    assert_equal "Item created.", flash[:notice], "Flash[:notice] must state that item was created"
    assert_equal "Exchange rate updated to #{assigns(:item).exchange_rate}.", flash[:alert], "Flash[:alert] must state that exchange rate changed"
    assert_equal @user1, assigns(:item).payer, "Item owner must be the payer"
    assigns(:item).event.users.each do |participant|
      assert participant.has_role?(:event_participant, assigns(:item)), "Event participants must have event participant role for items"
    end
    assert_empty assigns(:item).errors, "Item must not have errors"
  end

  test "non participant cannot create item" do
    new_item = { name: "New item", value_date: @event.from_date, description: "New description", 
      base_amount: 10, base_currency: "eur", exchange_rate: "",  
      foreign_amount: 10, foreign_currency: "eur", payer_id: @user1.id, 
      beneficiary_ids: [@organizer.id, @user1.id, @user3.id, @user4.id] }
      assert_no_difference('Item.count', message = "Item must not be created") do
        post :create, event_id: @event.id, item: new_item
      end
      assert_response :forbidden, "Response must be forbidden"
  end

  test "organizer can edit item" do
    sign_in @organizer
    get :edit, id: @item3.id
    assert_response :success, "Response must be success"
    assert_template :edit, "Edit page must be rendered"
    assert assigns(:item), "Item must be assigned"
  end

  test "participant cannot edit item" do
  	sign_in @user1
    get :edit, id: @item3.id
    assert_response :forbidden, "Response must be forbidden"
  end

  test "non participant cannot edit item" do
    get :edit, id: @item3.id
    assert_response :forbidden, "Response must be forbidden"
  end

  test "organizer can update item with manual exchange rate" do
  	sign_in @organizer
    new_item = { name: "Drinks", description: "Drinks", value_date: @event.from_date, 
      event: @event, base_amount: 67.03, base_currency: "eur", 
      exchange_rate: 0.1, foreign_amount: 500, foreign_currency: "DKK", 
      payer: @organizer, beneficiaries: [@organizer, @user1, @user2, @user3, @user4, @user5] }
    assert_no_difference('Item.count') do
      put :update, id: @item3.id, item: new_item
    end
    assert_equal 0.1*assigns(:item).foreign_amount, assigns(:item).base_amount
    assert_response :redirect, "Response must be redirect"
    assert_redirected_to item_path(assigns(:item))
    assert_equal "Item updated.", flash[:notice], "Flash[:notice] state that item was updated"
    assert_nil flash[:alert], "Flash[:alert] must be empty"
    assigns(:item).event.users.each do |participant|
      assert participant.has_role?(:event_participant, assigns(:item)), "Event participants must have event participant role for items"
    end
    assert_empty assigns(:item).errors, "Item must not have errors"
  end

  test "organizer can update item with automatic exchange rate" do
    sign_in @organizer
    new_item = { name: "Drinks", description: "Drinks", value_date: @event.from_date, 
      event: @event, base_amount: 67.03, base_currency: "eur", 
      exchange_rate: "", foreign_amount: 500, foreign_currency: "DKK", 
      payer: @organizer, beneficiaries: [@organizer, @user1, @user2, @user3, @user4, @user5] }
    stub_request(:get, "http://devel.farebookings.com/api/curconversor/DKK/EUR/1/json").to_return(:status => 200, :body => '{"EUR": 0.1}')
    assert_no_difference('Item.count') do
      put :update, id: @item3.id, item: new_item
    end
    assert_equal 0.1*assigns(:item).foreign_amount, assigns(:item).base_amount
    assert_response :redirect, "Response must be redirect"
    assert_redirected_to item_path(assigns(:item))
    assert_equal "Exchange rate updated to #{assigns(:item).exchange_rate}.", flash[:alert], "Flash[:alert] must state that exchange rate changed"
    assert_equal "Item updated.", flash[:notice], "Flash[:notice] state that item was updated"
    assigns(:item).event.users.each do |participant|
      participant.has_role? :event_participant, assigns(:item)
    end
    assert_empty assigns(:item).errors, "Item must not have errors"
  end

  test "organizer cannot update invalid item" do
    sign_in @organizer
    new_item = { name: "", value_date: @event.from_date, description: "New description", 
      base_amount: 10, base_currency: "eur", exchange_rate: 1,  
      foreign_amount: 10, foreign_currency: "eur", payer_id: @organizer.id, 
      beneficiary_ids: [@organizer.id, @user1.id, @user3.id, @user4.id] }
    assert_no_difference('Item.count') do
      put :update, id: @item3.id, item: new_item
    end
    assert_response :success, "Response must be success"
    assert_template :edit, "New page must be rendered"
    assert_equal "Item is invalid. Please correct.", flash[:notice], "Flash[:notice] state that item is invalid"
    assert_nil flash[:alert], "Flash[:alert] must be empty"
    assert_not_empty assigns(:item).errors, "Item errors must not be empty"
    assert_select "form div.row div.small-12.medium-8.large-6.columns.small-centered fieldset div.field.small-12.medium-4.large-4.columns.end .field_with_errors"
  end

  test "organizer cannot update invalid item (special case: automatic exchange rate update fails due to exception)" do
    sign_in @organizer
    new_item = { name: "New item", value_date: @event.from_date, description: "New description", 
      base_amount: 10, base_currency: "eur", exchange_rate: "",  
      foreign_amount: 10, foreign_currency: "eur", payer_id: @organizer.id, 
      beneficiary_ids: [@organizer.id, @user1.id, @user3.id, @user4.id] }
    stub_request(:get, "http://devel.farebookings.com/api/curconversor/EUR/EUR/1/json").to_raise(OpenURI::HTTPError.new(nil, ""))
    assert_no_difference('Item.count') do
      put :update, id: @item3.id, item: new_item
    end
    assert_response :success, "Response must be success"
    assert_template :edit, "New page must be rendered"
    assert_equal "Item is invalid. Please correct.", flash[:notice], "Flash[:notice] state that item is invalid"
    assert_nil flash[:alert], "Flash[:alert] must be empty"
    assert_not_empty assigns(:item).errors, "Item errors must not be empty"
    assert_select "form div.row div.small-12.medium-8.large-6.columns.small-centered fieldset div.field.small-12.medium-4.large-4.columns.end .field_with_errors"
  end

  test "organizer cannot update invalid item (special case: automatic exchange rate update fails due to time out)" do
    sign_in @organizer
    new_item = { name: "New item", value_date: @event.from_date, description: "New description", 
      base_amount: 10, base_currency: "eur", exchange_rate: "",  
      foreign_amount: 10, foreign_currency: "eur", payer_id: @organizer.id, 
      beneficiary_ids: [@organizer.id, @user1.id, @user3.id, @user4.id] }
    stub_request(:get, "http://devel.farebookings.com/api/curconversor/EUR/EUR/1/json").to_raise(Timeout::Error)
    assert_no_difference('Item.count') do
      put :update, id: @item3.id, item: new_item
    end
    assert_response :success, "Response must be success"
    assert_template :edit, "New page must be rendered"
    assert_equal "Item is invalid. Please correct.", flash[:notice], "Flash[:notice] state that item is invalid"
    assert_nil flash[:alert], "Flash[:alert] must be empty"
    assert_not_empty assigns(:item).errors, "Item errors must not be empty"
    assert_select "form div.row div.small-12.medium-8.large-6.columns.small-centered fieldset div.field.small-12.medium-4.large-4.columns.end .field_with_errors"
  end

  test "organizer cannot update invalid item (special case: automatic exchange rate update fails due to Rack time out)" do
    sign_in @organizer
    new_item = { name: "New item", value_date: @event.from_date, description: "New description", 
      base_amount: 10, base_currency: "eur", exchange_rate: "",  
      foreign_amount: 10, foreign_currency: "eur", payer_id: @organizer.id, 
      beneficiary_ids: [@organizer.id, @user1.id, @user3.id, @user4.id] }
    stub_request(:get, "http://devel.farebookings.com/api/curconversor/EUR/EUR/1/json").to_raise(Rack::Timeout::RequestTimeoutError)
    assert_no_difference('Item.count') do
      put :update, id: @item3.id, item: new_item
    end
    assert_response :success, "Response must be success"
    assert_template :edit, "New page must be rendered"
    assert_equal "Item is invalid. Please correct.", flash[:notice], "Flash[:notice] state that item is invalid"
    assert_nil flash[:alert], "Flash[:alert] must be empty"
    assert_not_empty assigns(:item).errors, "Item errors must not be empty"
    assert_select "form div.row div.small-12.medium-8.large-6.columns.small-centered fieldset div.field.small-12.medium-4.large-4.columns.end .field_with_errors"
  end

  test "participant cannot update item" do
  	sign_in @user2
    new_item = { name: "New item", value_date: @event.from_date, description: "New description", 
      base_amount: 10, base_currency: "eur", exchange_rate: "",  
      foreign_amount: 10, foreign_currency: "eur", payer_id: @organizer.id, 
      beneficiary_ids: [@organizer.id, @user1.id, @user3.id, @user4.id] }
      stub_request(:get, "http://devel.farebookings.com/api/curconversor/EUR/EUR/1/json").to_return(:status => 200, :body => '{"EUR": 1}')
    assert_no_difference('Item.count') do
      put :update, id: @item3.id, item: new_item
    end
    assert_response :forbidden, "Response must be forbidden"
  end
  
  test "non participant cannot update item" do
    new_item = { name: "New item", value_date: @event.from_date, description: "New description", 
      base_amount: 10, base_currency: "eur", exchange_rate: "",  
      foreign_amount: 10, foreign_currency: "eur", payer_id: @organizer.id, 
      beneficiary_ids: [@organizer.id, @user1.id, @user3.id, @user4.id] }
    stub_request(:get, "http://devel.farebookings.com/api/curconversor/EUR/EUR/1/json").to_return(:status => 200, :body => '{"EUR": 1}')
    assert_no_difference('Item.count') do
      put :update, id: @item3.id, item: new_item
    end
    assert_response :forbidden, "Response must be forbidden"
  end

  test "organizer can delete item" do
  	sign_in @organizer
    assert_difference('Item.count', -1) do
      delete :destroy, id: @item2.id
    end
    assert_response :redirect, "Response must be redirect"
    assert_redirected_to event_all_items_path(event_id: @event.id), "Redirect must be event_all_items_path"
    assert_equal "Item deleted.", flash[:notice], "Flash[:notice] must state that item was desleted"
    assert_not @organizer.has_role?(:event_participant, assigns(:item)), "Participant must not have event participant role for item anymore"
    assert_not @user1.has_role?(:event_participant, assigns(:item)), "Participant must not have event participant role for item anymore"
    assert_not @user2.has_role?(:event_participant, assigns(:item)), "Participant must not have event participant role for item anymore"
    assert_not @user3.has_role?(:event_participant, assigns(:item)), "Participant must not have event participant role for item anymore"
    assert_not @user4.has_role?(:event_participant, assigns(:item)), "Participant must not have event participant role for item anymore"
    assert_not @user5.has_role?(:event_participant, assigns(:item)), "Participant must not have event participant role for item anymore"
  end

  test "participant cannot delete item" do
  	sign_in @user2
    assert_no_difference('Item.count', message = "Item must not be destroyed") do
      delete :destroy, id: @item2.id
    end
    assert_response :forbidden, "Response must be forbidden"
  end

  test "non participant cannot delete item" do
  	assert_no_difference('Item.count', message = "Item must not be destroyed") do
      delete :destroy, id: @item2.id
    end
    assert_response :forbidden, "Response must be forbidden"
  end

  test "organizer can display item" do
  	sign_in @organizer
    get :show, id: @item6.id
    assert_response :success, "Response must be success"
    assert_template :show, "Show page must be rendered"
    assert_not_nil assigns(:item), "Item must be assigned"
  end

  test "participant can display item" do
    sign_in @user5
    get :show, id: @item6.id
    assert_response :success, "Response must be success"
    assert_template :show, "Show page must be rendered"
    assert_not_nil assigns(:item), "Item must be assigned"
  end

  test "non participant cannot display item" do
    get :show, id: @item6.id
    assert_response :forbidden, "Response must be forbidden"
  end

 #Test the views/pages

  test "items index page" do
    sign_in @organizer
    get :index, event_id: @event.id
    assert_select "title", "All your items of Randers event"

    # Test off-canvas menu
    assert_select ".left-off-canvas-menu ul li a[href=?]", event_all_items_path(assigns(:event)), "Back to all items"
    assert_select ".left-off-canvas-menu ul li a[href=?]", event_items_path(assigns(:event)), "Back to your items"
    assert_select ".left-off-canvas-menu ul li a[href=?]", events_path, "Back to events"
    assert_select ".left-off-canvas-menu ul li.has-submenu a[href='#']", "Randers event"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.back a[href='#']", "Back"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li a[href=?]", new_event_path, "Create new event"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li label", "Randers event"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li a[href=?]", invite_to_event_path(assigns(:event)), "Invite to event"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li a[href=?]", event_path(assigns(:event)), "View event details"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li a[href=?]", edit_event_path(assigns(:event)), "Edit event"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li a[href=?][data-method=delete]", event_path(assigns(:event)), "Delete event"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.has-submenu a[href='#']", "Expense Reports"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.has-submenu li.back a[href='#']", "Back"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.has-submenu li label", "Expense Reports"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.has-submenu li a[href=?]", expense_report_path(assigns(:event)), "Expense summary"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.has-submenu li a[href=?]", who_owes_you_path(assigns(:event)), "Who owes you?"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.has-submenu li a[href=?]", you_owe_whom_path(assigns(:event)), "You owe whom?"
    assert_select ".left-off-canvas-menu ul li.has-submenu a[href='#']", "Randers event"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.back a[href='#']", "Back"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li a[href=?]", new_event_item_path(assigns(:event)), "Create new item"
    
    # Test top-bar menu
    assert_select ".title-area li.name  h1  a[href='#']", "Come Malaka!"
    assert_select ".top-bar-section li a[href=?]", new_event_path, "Create new event"
    assert_select ".top-bar-section li.has-dropdown a[href='#']", "Back to ..."
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?]", events_path, "... events"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?]", event_all_items_path(assigns(:event)), "... all items (#{assigns(:event).name})"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li.active a[href=?]", event_items_path(assigns(:event)), "... your items (#{assigns(:event).name})"
    assert_select ".top-bar-section li.has-dropdown a[href='#']", "Randers event"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?]", invite_to_event_path(assigns(:event)), "Invite to event"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?]", event_path(assigns(:event)), "View event details"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?]", edit_event_path(assigns(:event)), "Edit event"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?][data-method=delete]", event_path(assigns(:event)), "Delete event"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li.has-dropdown a[href='#']", "Expense Reports"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li.has-dropdown ul.dropdown a[href=?]", expense_report_path(assigns(:event)), "Expense summary"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li.has-dropdown ul.dropdown li a[href=?]", who_owes_you_path(assigns(:event)), "Who owes you?"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li.has-dropdown ul.dropdown li a[href=?]", you_owe_whom_path(assigns(:event)), "You owe whom?"
    assert_select ".top-bar-section li.has-dropdown a[href='#']", "Randers items"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?]", new_event_item_path(assigns(:event)), "Create new item"

    # Test table
    table = "div.table-selector table.tablesaw[role=grid][data-tablesaw-mode=stack]"
    assert_select table + " caption", "Your items of event Randers"
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
    assigns(:items).each do |item|
      assert_select body + " a.dropdown[data-dropdown=?]", "action" + item.id.to_s, {text: item.name}
      li = body + " ul.f-dropdown#action#{item.id.to_s}[data-dropdown-content] li"
      assert_select li + " a[href=?]", item_path(item, item.event), "View item details"
      assert_select li + " a[href=?]", edit_item_path(item), "Edit item"
      assert_select li + " a[href=?][data-confirm][data-method=delete]", item_path(item), "Delete item"
      assert_select body, item.value_date.strftime('%d %b %Y')
      assert_select body, item.description
      assert_select body + " span.has-tip[data-tooltip][title=?]", "Euro", money_format(item.base_amount, item.base_currency)
      assert_select body, item.exchange_rate.to_s
      assert_select body + " span.has-tip[data-tooltip][title=?]", "Danish Krone", money_format(item.foreign_amount, item.foreign_currency)
      assert_select body, item.payer.short_name
      assert_select body + " span.has-tip[data-tooltip][title=?]", item.beneficiaries.map{ |b| b.short_name }.join(', '), item.beneficiaries.count.to_s
      assert_select body, money_format(item.cost_per_beneficiary, item.base_currency)
    end
  end

  test "items new page" do
    sign_in @organizer
    get :new, event_id: @event.id

    # Test off-canvas menu
    assert_select "title", "Create new item in Randers event"
    assert_select ".left-off-canvas-menu ul li a[href=?]", event_all_items_path(assigns(:item).event), "Back to all items"
    assert_select ".left-off-canvas-menu ul li a[href=?]", event_items_path(assigns(:item).event), "Back to your items"
    assert_select ".left-off-canvas-menu ul li a[href=?]", events_path, "Back to events"
    assert_select ".left-off-canvas-menu ul li.has-submenu a[href='#']", "Randers event"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.back a[href='#']", "Back"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li a[href=?]", new_event_path, "Create new event"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li label", "Randers event"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li a[href=?]", invite_to_event_path(assigns(:item).event), "Invite to event"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li a[href=?]", event_path(assigns(:item).event), "View event details"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li a[href=?]", edit_event_path(assigns(:item).event), "Edit event"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li a[href=?][data-method=delete]", event_path(assigns(:item).event), "Delete event"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.has-submenu a[href='#']", "Expense Reports"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.has-submenu li.back a[href='#']", "Back"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.has-submenu li label", "Expense Reports"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.has-submenu li a[href=?]", expense_report_path(assigns(:item).event), "Expense summary"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.has-submenu li a[href=?]", who_owes_you_path(assigns(:item).event), "Who owes you?"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.has-submenu li a[href=?]", you_owe_whom_path(assigns(:item).event), "You owe whom?"
    assert_select ".left-off-canvas-menu ul li.has-submenu a[href='#']", "Randers event"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.back a[href='#']", "Back"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li a[href=?]", new_event_item_path(assigns(:item).event), "Create new item"

    # Test top-bar menu
    assert_select ".title-area li.name  h1  a[href='#']", "Come Malaka!"
    assert_select ".top-bar-section li a[href=?]", new_event_path, "Create new event"
    assert_select ".top-bar-section li.has-dropdown a[href='#']", "Back to ..."
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?]", events_path, "... events"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?]", event_all_items_path(assigns(:item).event), "... all items (#{assigns(:item).event.name})"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?]", event_items_path(assigns(:item).event), "... your items (#{assigns(:item).event.name})"
    assert_select ".top-bar-section li.has-dropdown a[href='#']", "Randers event"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?]", invite_to_event_path(assigns(:item).event), "Invite to event"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?]", event_path(assigns(:item).event), "View event details"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?]", edit_event_path(assigns(:item).event), "Edit event"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?][data-method=delete]", event_path(assigns(:item).event), "Delete event"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li.has-dropdown a[href='#']", "Expense Reports"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li.has-dropdown ul.dropdown a[href=?]", expense_report_path(assigns(:item).event), "Expense summary"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li.has-dropdown ul.dropdown li a[href=?]", who_owes_you_path(assigns(:item).event), "Who owes you?"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li.has-dropdown ul.dropdown li a[href=?]", you_owe_whom_path(assigns(:item).event), "You owe whom?"
    assert_select ".top-bar-section li.has-dropdown a[href='#']", "Randers items"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li.active a[href=?]", new_event_item_path(assigns(:item).event), "Create new item"

    #Test form and Foundation Abide and Grid
    assert_select "form[data-abide=true][novalidate=novalidate]"
    assert_select "form div.row div.small-12.medium-8.large-6.columns.small-centered fieldset" do
      assert_select "legend", "Create new item"
      
      assert_select "div.row", 11
      label = "div.field.small-12.medium-4.large-4.columns.end label"
      input = "div.small-12.medium-8.large-8.columns.end input"
      error = "div.small-12.medium-8.large-8.columns.end small.error"

      assert_select label, "Name"
      assert_select input + "#item_name[required=required]" 
      assert_select error, "Please name the item."
      assert_select label, "Name"
      assert_select input + "#item_description[required=required]" 
      assert_select error, "Please describe the item."
      assert_select label, "Value date"
      assert_select input + "#item_value_date[required=required][size=?]", "10" 
      assert_select error, "Please choose a value date for the item."
      assert_select label, "Payer"
      assert_select "div.small-12.medium-8.large-8.columns.end select#item_payer_id" do
        assert_select "option[selected=selected][value=?]", @organizer.id.to_s, {text: "Lasse Lund"}
        assigns(:item).event.users.each do |participant|
          next unless participant != @organizer
          assert_select "option[value=?]", participant.id.to_s, {text: participant.name}
        end
      end
      assert_select label, "Base amount"
      assert_select input + "#item_base_amount[readonly=readonly][placeholder=?]", "= Exchange rate * Foreign amount" 
      assert_select label, "Base currency"
      assert_select input + "#item_base_currency[type=hidden][value=eur]"
      assert_select input + "#item_dummy[disabled=disabled][value=EUR]"
      assert_select label, "Exchange rate"
      assert_select input + "#item_exchange_rate[required=required][pattern='exchange_rate'][placeholder=?]", "Put 0 to fetch currency automatically"
      assert_select error, "Exchange rate must be a positive number."
      assert_select label, "Foreign amount"
      assert_select input + "#item_foreign_amount[required=required][pattern='amount']"
      assert_select error, "Please type in how much you paid for the item."
      assert_select "div.small-12.medium-8.large-8.columns.end select#item_foreign_currency" do
        assert_select "#item_foreign_currency[required=required]"
        assert_select "option[value=?]", "", {text: "Select foreign currency"}
        Money::Currency.all.each do |currency|
          assert_select "option[value=?]", currency.id.to_s, {text: currency.iso_code.to_s}
        end
      end
      assert_select error, "Please choose a currency."
      assert_select label, "Beneficiaries"
      assigns(:item).event.users.each do |beneficiary|
        assert_select "div.row div.small-12.medium-8.large-8.columns.end label[for=?]", "item_beneficiary_ids_" + beneficiary.id.to_s, {text: beneficiary.name}
        assert_select "div.row div.small-12.medium-8.large-8.columns.end label input#item_beneficiary_ids_" + beneficiary.id.to_s + "[value=?]", beneficiary.id.to_s 
      end
      assert_select "div.actions.small-12.medium-8.large-8.columns.end input[value=?]", "Post item"
    end
  end

  test "items edit page" do
    sign_in @organizer
    get :edit, id: @item1.id
    assert_select "title", "Details for Food item"

    # Test off-canvas menu
    assert_select ".left-off-canvas-menu ul li a[href=?]", event_all_items_path(assigns(:item).event), "Back to all items"
    assert_select ".left-off-canvas-menu ul li a[href=?]", event_items_path(assigns(:item).event), "Back to your items"
    assert_select ".left-off-canvas-menu ul li a[href=?]", events_path, "Back to events"
    assert_select ".left-off-canvas-menu ul li.has-submenu a[href='#']", "Randers event"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.back a[href='#']", "Back"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li a[href=?]", new_event_path(assigns(:item).event), "Create new event"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li label", "Randers event"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li a[href=?]", invite_to_event_path(assigns(:item).event), "Invite to event"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li a[href=?]", event_path(assigns(:item).event), "View event details"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li a[href=?]", edit_event_path(assigns(:item).event), "Edit event"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li a[href=?][data-method=delete]", event_path(assigns(:item).event), "Delete event"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.has-submenu a[href='#']", "Expense Reports"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.has-submenu li.back a[href='#']", "Back"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.has-submenu li label", "Expense Reports"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.has-submenu li a[href=?]", expense_report_path(assigns(:item).event), "Expense summary"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.has-submenu li a[href=?]", who_owes_you_path(assigns(:item).event), "Who owes you?"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.has-submenu li a[href=?]", you_owe_whom_path(assigns(:item).event), "You owe whom?"
    assert_select ".left-off-canvas-menu ul li.has-submenu a[href='#']", "Randers event"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.back a[href='#']", "Back"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li a[href=?]", new_event_item_path(assigns(:item).event), "Create new item"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li label", "Food item"    
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li a[href=?]", item_path(assigns(:item)), "View item details"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li a[href=?]", edit_item_path(assigns(:item)), "Edit item"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li a[href=?][data-method=delete]", item_path(assigns(:item)), "Delete item"

    # Test top-bar menu
    assert_select ".title-area li.name  h1  a[href='#']", "Come Malaka!"
    assert_select ".top-bar-section li a[href=?]", new_event_path, "Create new event"
    assert_select ".top-bar-section li.has-dropdown a[href='#']", "Back to ..."
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?]", events_path, "... events"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?]", event_all_items_path(assigns(:item).event), "... all items (#{assigns(:item).event.name})"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?]", event_items_path(assigns(:item).event), "... your items (#{assigns(:item).event.name})"
    assert_select ".top-bar-section li.has-dropdown a[href='#']", "Randers event"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?]", invite_to_event_path(assigns(:item).event), "Invite to event"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?]", event_path(assigns(:item).event), "View event details"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?]", edit_event_path(assigns(:item).event), "Edit event"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?][data-method=delete]", event_path(assigns(:item).event), "Delete event"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li.has-dropdown a[href='#']", "Expense Reports"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li.has-dropdown ul.dropdown a[href=?]", expense_report_path(assigns(:item).event), "Expense summary"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li.has-dropdown ul.dropdown li a[href=?]", who_owes_you_path(assigns(:item).event), "Who owes you?"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li.has-dropdown ul.dropdown li a[href=?]", you_owe_whom_path(assigns(:item).event), "You owe whom?"
    assert_select ".top-bar-section li.has-dropdown a[href='#']", "Randers items"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?]", new_event_item_path(assigns(:item).event), "Create new item"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?]", item_path(assigns(:item)), "View item details"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li.active a[href=?]", edit_item_path(assigns(:item)), "Edit item"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?][data-method=delete]", item_path(assigns(:item)), "Delete item"

    #Test form and Foundation Abide and Grid
    assert_select "form[data-abide=true][novalidate=novalidate]"
    assert_select "form div.row div.small-12.medium-8.large-6.columns.small-centered fieldset" do
      assert_select "legend", "Edit item"
      
      assert_select "div.row", 11
      label = "div.row div.field.small-12.medium-4.large-4.columns.end label"
      input = "div.row div.small-12.medium-8.large-8.columns.end input"
      error = "div.row div.small-12.medium-8.large-8.columns.end small.error"

      assert_select label, "Name"
      assert_select input + "#item_name[required=required][value=?]", "Food"
      assert_select error, "Please name the item."
      assert_select label, "Name"
      assert_select input + "#item_description[required=required][value=?]", "Food"
      assert_select error, "Please describe the item."
      assert_select label, "Value date"
      assert_select input + "#item_value_date[required=required][size='10'][value=?]", "2012-11-02"
      assert_select error, "Please choose a value date for the item."
      assert_select label, "Payer"
      assert_select "div.small-12.medium-8.large-8.columns.end select#item_payer_id" do
        assert_select "option[selected=selected][value=?]", @organizer.id.to_s, {text: "Lasse Lund"}
        assigns(:item).event.users.each do |participant|
          next unless participant != @organizer
          assert_select "option[value=?]", participant.id.to_s, {text: participant.name}
        end
      end
      assert_select label, "Base amount"
      assert_select input + "#item_base_amount[readonly=readonly][placeholder=?]", "= Exchange rate * Foreign amount"
      assert_select input + "#item_base_amount[value=?]", "241.3000000000000000000000008"
      assert_select label, "Base currency"
      assert_select input + "#item_base_currency[disabled=disabled][value=EUR]"
      assert_select label, "Exchange rate"
      assert_select input + "#item_exchange_rate[required=required][pattern='exchange_rate'][placeholder=?]", "Put 0 to fetch currency automatically"
      assert_select input + "#item_exchange_rate:match('value', ?)", /0\.13405555555/
      assert_select error, "Exchange rate must be a positive number."
      assert_select label, "Foreign amount"
      assert_select input + "#item_foreign_amount[required=required][pattern='amount'][value=?]", "1800.0"
      assert_select error, "Please type in how much you paid for the item."
      assert_select "div.small-12.medium-8.large-8.columns.end select#item_foreign_currency" do
        Money::Currency.all.each do |currency|
          assert_select "option[value=?]", currency.id.to_s, {text: currency.iso_code.to_s}
        end
      end
      assert_select error, "Please choose a currency."
      assert_select label, "Beneficiaries"
      assigns(:item).event.users.each do |participant|
        assert_select "div.row div.small-12.medium-8.large-8.columns.end label[for=?]", "item_beneficiary_ids_" + participant.id.to_s, {text: participant.short_name}
        assert_select "div.row div.small-12.medium-8.large-8.columns.end label input#item_beneficiary_ids_" + participant.id.to_s + "[value=?]", participant.id.to_s 
        if assigns(:item).beneficiaries.include?(participant) then
          assert_select "div.row div.small-12.medium-8.large-8.columns.end label input#item_beneficiary_ids_" + participant.id.to_s + "[checked=checked]"
        end
      end
      assert_select "div.actions.small-12.medium-8.large-8.columns.end input[value=?]", "Post item"
    end
  end

  test "items show page (payer's display)" do
    sign_in @organizer
    get :show, id: @item1.id
    assert_select "title", "Details about item Food"

    # Test off-canvas menu
    assert_select ".left-off-canvas-menu ul li a[href=?]", event_all_items_path(assigns(:item).event), "Back to all items"
    assert_select ".left-off-canvas-menu ul li a[href=?]", event_items_path(assigns(:item).event), "Back to your items"
    assert_select ".left-off-canvas-menu ul li a[href=?]", events_path, "Back to events"
    assert_select ".left-off-canvas-menu ul li.has-submenu a[href='#']", "Randers event"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.back a[href='#']", "Back"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li a[href=?]", new_event_path(assigns(:item).event), "Create new event"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li label", "Randers event"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li a[href=?]", invite_to_event_path(assigns(:item).event), "Invite to event"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li a[href=?]", event_path(assigns(:item).event), "View event details"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li a[href=?]", edit_event_path(assigns(:item).event), "Edit event"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li a[href=?][data-method=delete]", event_path(assigns(:item).event), "Delete event"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.has-submenu a[href='#']", "Expense Reports"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.has-submenu li.back a[href='#']", "Back"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.has-submenu li label", "Expense Reports"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.has-submenu li a[href=?]", expense_report_path(assigns(:item).event), "Expense summary"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.has-submenu li a[href=?]", who_owes_you_path(assigns(:item).event), "Who owes you?"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.has-submenu li a[href=?]", you_owe_whom_path(assigns(:item).event), "You owe whom?"
    assert_select ".left-off-canvas-menu ul li.has-submenu a[href='#']", "Randers event"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.back a[href='#']", "Back"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li a[href=?]", new_event_item_path(assigns(:item).event), "Create new item"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li label", "Food item"    
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li a[href=?]", item_path(assigns(:item)), "View item details"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li a[href=?]", edit_item_path(assigns(:item)), "Edit item"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li a[href=?][data-method=delete]", item_path(assigns(:item)), "Delete item"

    # Test top-bar menu
    assert_select ".title-area li.name  h1  a[href='#']", "Come Malaka!"
    assert_select ".top-bar-section li a[href=?]", new_event_path, "Create new event"
    assert_select ".top-bar-section li.has-dropdown a[href='#']", "Back to ..."
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?]", events_path, "... events"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?]", event_all_items_path(assigns(:item).event), "... all items (#{assigns(:item).event.name})"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?]", event_items_path(assigns(:item).event), "... your items (#{assigns(:item).event.name})"
    assert_select ".top-bar-section li.has-dropdown a[href='#']", "Randers event"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?]", invite_to_event_path(assigns(:item).event), "Invite to event"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?]", event_path(assigns(:item).event), "View event details"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?]", edit_event_path(assigns(:item).event), "Edit event"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?][data-method=delete]", event_path(assigns(:item).event), "Delete event"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li.has-dropdown a[href='#']", "Expense Reports"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li.has-dropdown ul.dropdown a[href=?]", expense_report_path(assigns(:item).event), "Expense summary"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li.has-dropdown ul.dropdown li a[href=?]", who_owes_you_path(assigns(:item).event), "Who owes you?"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li.has-dropdown ul.dropdown li a[href=?]", you_owe_whom_path(assigns(:item).event), "You owe whom?"
    assert_select ".top-bar-section li.has-dropdown a[href='#']", "Randers items"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?]", new_event_item_path(assigns(:item).event), "Create new item"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li.active a[href=?]", item_path(assigns(:item)), "View item details"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?]", edit_item_path(assigns(:item)), "Edit item"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?][data-method=delete]", item_path(assigns(:item)), "Delete item"


    #Test form and Foundation Grid
    assert_select "form div.row div.small-12.medium-8.large-6.columns.small-centered fieldset[disabled]" do
      assert_select "legend", "Show item details"
      
      assert_select "div.row", 10
      label = "div.row div.field.small-12.medium-4.large-4.columns.end label"
      input = "div.row div.small-12.medium-8.large-8.columns.end input"
      error = "div.row div.small-12.medium-8.large-8.columns.end small.error"

      assert_select label, "Name"
      assert_select input + "#item_name[value=?]", "Food"
      assert_select label, "Name"
      assert_select input + "#item_description[value=?]", "Food"
      assert_select label, "Value date"
      assert_select input + "#item_value_date[size='10'][value=?]", "2012-11-02"
      assert_select label, "Payer"
      assert_select input + "#dummy[value=?]", "Lasse Lund"
      assert_select label, "Base amount"
      assert_select input + "#item_base_amount[value=?]", "241.3000000000000000000000008"
      assert_select label, "Base currency"
      assert_select input + "#item_base_currency[value='EUR']"
      assert_select label, "Exchange rate"
      assert_select input + "#item_exchange_rate:match('value', ?)", /0\.13405555555/
      assert_select label, "Foreign amount"
      assert_select input + "#item_foreign_amount[value=?]", "1800.0"
      assert_select "div.small-12.medium-8.large-8.columns.end select#item_foreign_currency" do
        Money::Currency.all.each do |currency|
          assert_select "option[value=?]", currency.id.to_s, {text: currency.iso_code.to_s}
        end
      end
      assert_select label, "Beneficiaries"
      assigns(:item).event.users.each do |participant|
        assert_select "div.row div.small-12.medium-8.large-8.columns.end label[for=?]", "item_beneficiary_ids_" + participant.id.to_s, {text: participant.short_name}
        assert_select "div.row div.small-12.medium-8.large-8.columns.end label input#item_beneficiary_ids_" + participant.id.to_s + "[value=?]", participant.id.to_s 
        if assigns(:item).beneficiaries.include?(participant) then
          assert_select "div.row div.small-12.medium-8.large-8.columns.end label input#item_beneficiary_ids_" + participant.id.to_s + "[checked=checked]"
        end
      end
    end
  end

  test "items show page (non payer's display)" do
    sign_in @user1
    get :show, id: @item1.id
    assert_select "title", "Details about item Food"

    # Test off-canvas menu
    assert_select ".left-off-canvas-menu ul li a[href=?]", event_all_items_path(assigns(:item).event), "Back to all items"
    assert_select ".left-off-canvas-menu ul li a[href=?]", event_items_path(assigns(:item).event), "Back to your items"
    assert_select ".left-off-canvas-menu ul li a[href=?]", events_path, "Back to events"
    assert_select ".left-off-canvas-menu ul li.has-submenu a[href='#']", "Randers event"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.back a[href='#']", "Back"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li a[href=?]", new_event_path(assigns(:item).event), "Create new event"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li label", "Randers event"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li a[href=?]", event_path(assigns(:item).event), "View event details"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.has-submenu a[href='#']", "Expense Reports"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.has-submenu li.back a[href='#']", "Back"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.has-submenu li label", "Expense Reports"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.has-submenu li a[href=?]", expense_report_path(assigns(:item).event), "Expense summary"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.has-submenu li a[href=?]", who_owes_you_path(assigns(:item).event), "Who owes you?"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.has-submenu li a[href=?]", you_owe_whom_path(assigns(:item).event), "You owe whom?"
    assert_select ".left-off-canvas-menu ul li.has-submenu a[href='#']", "Randers event"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.back a[href='#']", "Back"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li a[href=?]", new_event_item_path(assigns(:item).event), "Create new item"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li label", "Food item"    
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li a[href=?]", item_path(assigns(:item)), "View item details"

    # Test top-bar menu
    assert_select ".title-area li.name  h1  a[href='#']", "Come Malaka!"
    assert_select ".top-bar-section li a[href=?]", new_event_path, "Create new event"
    assert_select ".top-bar-section li.has-dropdown a[href='#']", "Back to ..."
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?]", events_path, "... events"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?]", event_all_items_path(assigns(:item).event), "... all items (#{assigns(:item).event.name})"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?]", event_items_path(assigns(:item).event), "... your items (#{assigns(:item).event.name})"
    assert_select ".top-bar-section li.has-dropdown a[href='#']", "Randers event"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?]", event_path(assigns(:item).event), "View event details"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li.has-dropdown a[href='#']", "Expense Reports"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li.has-dropdown ul.dropdown a[href=?]", expense_report_path(assigns(:item).event), "Expense summary"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li.has-dropdown ul.dropdown li a[href=?]", who_owes_you_path(assigns(:item).event), "Who owes you?"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li.has-dropdown ul.dropdown li a[href=?]", you_owe_whom_path(assigns(:item).event), "You owe whom?"
    assert_select ".top-bar-section li.has-dropdown a[href='#']", "Randers items"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?]", new_event_item_path(assigns(:item).event), "Create new item"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li.active a[href=?]", item_path(assigns(:item)), "View item details"

    #Test form and Foundation Grid
    assert_select "form div.row div.small-12.medium-8.large-6.columns.small-centered fieldset[disabled]" do
      assert_select "legend", "Show item details"
      
      assert_select "div.row", 10
      label = "div.row div.field.small-12.medium-4.large-4.columns.end label"
      input = "div.row div.small-12.medium-8.large-8.columns.end input"
      error = "div.row div.small-12.medium-8.large-8.columns.end small.error"

      assert_select label, "Name"
      assert_select input + "#item_name[value=?]", "Food"
      assert_select label, "Name"
      assert_select input + "#item_description[value=?]", "Food"
      assert_select label, "Value date"
      assert_select input + "#item_value_date[size='10'][value=?]", "2012-11-02"
      assert_select label, "Payer"
      assert_select input + "#dummy[value=?]", "Lasse Lund"
      assert_select label, "Base amount"
      assert_select input + "#item_base_amount[value=?]", "241.3000000000000000000000008"
      assert_select label, "Base currency"
      assert_select input + "#item_base_currency[value='EUR']"
      assert_select label, "Exchange rate"
      assert_select input + "#item_exchange_rate:match('value', ?)", /0\.13405555555/
      assert_select label, "Foreign amount"
      assert_select input + "#item_foreign_amount[value=?]", "1800.0"
      assert_select "div.small-12.medium-8.large-8.columns.end select#item_foreign_currency" do
        Money::Currency.all.each do |currency|
          assert_select "option[value=?]", currency.id.to_s, {text: currency.iso_code.to_s}
        end
      end
      assert_select label, "Beneficiaries"
      assigns(:item).event.users.each do |participant|
        assert_select "div.row div.small-12.medium-8.large-8.columns.end label[for=?]", "item_beneficiary_ids_" + participant.id.to_s, {text: participant.short_name}
        assert_select "div.row div.small-12.medium-8.large-8.columns.end label input#item_beneficiary_ids_" + participant.id.to_s + "[value=?]", participant.id.to_s 
        if assigns(:item).beneficiaries.include?(participant) then
          assert_select "div.row div.small-12.medium-8.large-8.columns.end label input#item_beneficiary_ids_" + participant.id.to_s + "[checked=checked]"
        end
      end
    end
  end

end
