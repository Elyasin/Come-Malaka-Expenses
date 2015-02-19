require 'test_helper'
require 'webmock/minitest'
require 'open-uri'

class ItemsControllerTest < ActionController::TestCase

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
      base_amount: 10, base_currency: "EUR", exchange_rate: 1,  
      foreign_amount: 10, foreign_currency: "EUR", payer_id: @organizer.id, 
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
      base_amount: 10, base_currency: "EUR", exchange_rate: "",  
      foreign_amount: 10, foreign_currency: "EUR", payer_id: @organizer.id, 
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
      base_amount: 10, base_currency: "EUR", exchange_rate: 1,  
      foreign_amount: 10, foreign_currency: "EUR", payer_id: @organizer.id, 
      beneficiary_ids: [@organizer.id, @user1.id, @user3.id, @user4.id] }
      assert_no_difference('Item.count', message = "Item must not be created") do
        post :create, event_id: @event.id, item: new_item
      end
      assert_response :success, "Response must be success"
      assert_template :new, "New page must be rendered"
      assert_equal "Item is invalid. Please correct.", flash[:notice], "Flash[:notice] state that item is invalid"
      assert_nil flash[:alert], "Flash[:alert] must be empty"
      assert_not_empty assigns(:item).errors, "Item errors must not be empty"
  end

  test "organizer cannot create invalid item (special case: automatic exchange rate update fails)" do
    sign_in @organizer
    new_item = { name: "New item", value_date: @event.from_date, description: "New description", 
      base_amount: 10, base_currency: "EUR", exchange_rate: "",  
      foreign_amount: 10, foreign_currency: "EUR", payer_id: @organizer.id, 
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
  end

  test "participant can create valid item with manual exchange currency" do
    sign_in @user1
    new_item = { name: "New item", value_date: @event.from_date, description: "New description", 
      base_amount: 10, base_currency: "EUR", exchange_rate: 1,  
      foreign_amount: 10, foreign_currency: "EUR", payer_id: @user1.id, 
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
      base_amount: 10, base_currency: "EUR", exchange_rate: "",  
      foreign_amount: 10, foreign_currency: "EUR", payer_id: @user1.id, 
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
      base_amount: 10, base_currency: "EUR", exchange_rate: "",  
      foreign_amount: 10, foreign_currency: "EUR", payer_id: @user1.id, 
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
      event: @event, base_amount: 67.03, base_currency: "EUR", 
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
      event: @event, base_amount: 67.03, base_currency: "EUR", 
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
    new_item = { name: nil, value_date: @event.from_date, description: "New description", 
      base_amount: 10, base_currency: "EUR", exchange_rate: 1,  
      foreign_amount: 10, foreign_currency: "EUR", payer_id: @organizer.id, 
      beneficiary_ids: [@organizer.id, @user1.id, @user3.id, @user4.id] }
      assert_no_difference('Item.count') do
        put :update, id: @item3.id, item: new_item
      end
      assert_response :success, "Response must be success"
      assert_template :edit, "New page must be rendered"
      assert_equal "Item is invalid. Please correct.", flash[:notice], "Flash[:notice] state that item is invalid"
      assert_nil flash[:alert], "Flash[:alert] must be empty"
      assert_not_empty assigns(:item).errors, "Item errors must not be empty"
  end

  test "organizer cannot update invalid item (special case: automatic exchange rate update fails due to exception)" do
    sign_in @organizer
    new_item = { name: "New item", value_date: @event.from_date, description: "New description", 
      base_amount: 10, base_currency: "EUR", exchange_rate: "",  
      foreign_amount: 10, foreign_currency: "EUR", payer_id: @organizer.id, 
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
  end

  test "organizer cannot update invalid item (special case: automatic exchange rate update fails due to time out)" do
    sign_in @organizer
    new_item = { name: "New item", value_date: @event.from_date, description: "New description", 
      base_amount: 10, base_currency: "EUR", exchange_rate: "",  
      foreign_amount: 10, foreign_currency: "EUR", payer_id: @organizer.id, 
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
  end

  test "organizer cannot update invalid item (special case: automatic exchange rate update fails due to Rack time out)" do
    sign_in @organizer
    new_item = { name: "New item", value_date: @event.from_date, description: "New description", 
      base_amount: 10, base_currency: "EUR", exchange_rate: "",  
      foreign_amount: 10, foreign_currency: "EUR", payer_id: @organizer.id, 
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
  end

  test "participant cannot update item" do
  	sign_in @user2
    new_item = { name: "New item", value_date: @event.from_date, description: "New description", 
      base_amount: 10, base_currency: "EUR", exchange_rate: "",  
      foreign_amount: 10, foreign_currency: "EUR", payer_id: @organizer.id, 
      beneficiary_ids: [@organizer.id, @user1.id, @user3.id, @user4.id] }
      stub_request(:get, "http://devel.farebookings.com/api/curconversor/EUR/EUR/1/json").to_return(:status => 200, :body => '{"EUR": 1}')
    assert_no_difference('Item.count') do
      put :update, id: @item3.id, item: new_item
    end
    assert_response :forbidden, "Response must be forbidden"
  end
  
  test "non participant cannot update item" do
    new_item = { name: "New item", value_date: @event.from_date, description: "New description", 
      base_amount: 10, base_currency: "EUR", exchange_rate: "",  
      foreign_amount: 10, foreign_currency: "EUR", payer_id: @organizer.id, 
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
    assert_redirected_to event_items_path(event_id: @event.id), "Redirect must be event_items_path"
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

end
