require 'test_helper'
require 'webmock/minitest'
require 'open-uri'

class ItemTest < ActiveSupport::TestCase

	#Test data initialized in test_helper.rb#setup
	#and truncated while teardown


	test "do not save item without name" do
		@item1.name = nil
		assert_not @item1.save, "Item must have a name"
	end

	test "do not save item without description" do
		@item1.description = nil
		assert_not @item1.save, "Item must have a description"
	end

	test "do not save item without value date" do
		@item1.value_date = nil
		assert_not @item1.save, "Item must have a value date"
	end

	test "do not save item without event" do
		@item1.event = nil
		assert_not @item1.save, "Item must belong to an event"
	end

	test "item's base amount is validated before save" do
		@item1.base_amount = nil
		assert @item1.save, "Item must have a base amount"
		assert_not_nil @item1.base_amount
	end

	test "do not save item without base currency" do
		@item1.base_currency = nil
		assert_not @item1.save, "Item must have a base currency"
	end

	test "do not save item without exchange rate" do
		stub_request(:get, "http://devel.farebookings.com/api/curconversor/DKK/EUR/1/json").to_raise(OpenURI::HTTPError.new(nil, ""))
		@item1.exchange_rate = nil
		assert_not @item1.save, "Item must have an exchange rate"
	end

	test "do not save item without foreign amount" do
		@item1.foreign_amount = nil
		assert_not @item1.save, "Item must have a foreign amount"
	end

	test "do not save item without foreign currency" do
		@item1.foreign_currency = nil
		assert_not @item1.save, "Item must have a foreign currency"
	end

	test "do not save item without payer" do
		@item1.payer = nil
		assert_not @item1.save, "Item must have a payer"
	end

	test "do not save item without beneficiaries" do
		@item1.beneficiaries = nil
		assert_not @item1.save, "Item must have at least one beneficiary"
	end

	test "exchange rate must be greate or equal than 0" do
		@item1.exchange_rate = -1
		assert_not @item1.save, "Item's exchange rate must be >= 0"
	end

	test "exchange rate must be a number" do
		@item1.exchange_rate = "NaN"
		assert_not @item1.save, "Item's exchange rate must be a number"
	end

	test "foreign amount must be positive" do
		@item1.foreign_amount = -1
		assert_not @item1.save, "Item's foreign amount must be >= 0"
	end
	
	test "foreign amount must be a number" do
		@item1.foreign_amount = "NaN"
		assert_not @item1.save, "Item's foreign amount must be a number"
	end
	
	test "item's cost per beneficiary" do
		assert_in_delta (241.30.to_d/6), @item1.cost_per_beneficiary, 0.0000000000000001, "Item 1 cpb must be 241.3/6"
		assert_in_delta  (67.03.to_d/6), @item2.cost_per_beneficiary, 0.0000000000000001, "Item 2 cpb must be 67.03/6"
		assert_in_delta  (67.03.to_d/6), @item3.cost_per_beneficiary, 0.0000000000000001, "Item 3 cpb must be 67.03/6"
		assert_in_delta (147.46.to_d/4), @item4.cost_per_beneficiary, 0.0000000000000001, "Item 4 cpb must be 147.46/4"
		assert_in_delta (147.46.to_d/6), @item5.cost_per_beneficiary, 0.0000000000000001, "Item 5 cpb must be 147.46/6"
		assert_in_delta  (10.72.to_d/6), @item6.cost_per_beneficiary, 0.0000000000000001, "Item 6 cpb must be 10.72/6"
	end

	test "apply exchange rate on item successfully" do
		@item1.exchange_rate = ""
		stub_request(:get, "http://devel.farebookings.com/api/curconversor/DKK/EUR/1/json").to_return(:status => 200, :body => '{"EUR": 0.1343}')
		@item1.apply_exchange_rate
		assert_equal 0.1343.to_d, @item1.exchange_rate, "Item's new exchange rate must be 0.1343"
		assert_equal 0.1343.to_d*@item1.foreign_amount, @item1.base_amount, "Item's new base_amount must correspond to new exchange rate"
	end

	test "apply exchange rate on item manually" do
		assert_not_nil @item1.exchange_rate.blank?
		assert_no_difference('@item1.exchange_rate') do
			@item1.apply_exchange_rate
		end
	end

	test "time out error when requesting exchange rate for item" do
		stub_request(:any, "http://devel.farebookings.com/api/curconversor/DKK/EUR/1/json").to_raise(Timeout::Error)
		@item1.exchange_rate = ""
		@item1.apply_exchange_rate
		assert_equal 1, @item1.errors[:exchange_rate].length, "Item exchange rate must have error message"
		assert @item1.invalid?
	end

	test "connection error when requesting exchange rate for item" do
		stub_request(:any, "http://devel.farebookings.com/api/curconversor/DKK/EUR/1/json").to_raise(OpenURI::HTTPError.new(nil, ""))
		@item1.exchange_rate = ""
		@item1.apply_exchange_rate
		assert_equal 1, @item1.errors[:exchange_rate].length, "Item exchange rate must have error message"
		assert @item1.invalid?
	end

	test "rack timeout error when requesting exchange rate for item" do
		stub_request(:any, "http://devel.farebookings.com/api/curconversor/DKK/EUR/1/json").to_raise(Rack::Timeout::RequestTimeoutError.new)
		@item1.exchange_rate = ""
		@item1.apply_exchange_rate
		assert_equal 1, @item1.errors[:exchange_rate].length, "Item exchange rate must have error message"
		assert @item1.invalid?
	end

	#Test classe level authorization

	test "event user role can create item" do
		assert ItemAuthorizer.creatable_by?(@organizer), "Organizer must have create access"
		assert ItemAuthorizer.creatable_by?(@user1), "User 1 must have create access"
	end

	test "user without event user role cannot create item" do
		assert ItemAuthorizer.creatable_by?(@user1), "User 1 must have create access"
		@user1.revoke :event_user
		assert_not ItemAuthorizer.creatable_by?(@user1), "User 1 must not have create access after revocation of event user role"
	end

	test "event user can read item" do
		assert ItemAuthorizer.readable_by?(@organizer), "Organizer must have read access"
		assert ItemAuthorizer.readable_by?(@user1), "User 1 must have read access"
	end

	test "user without event user role cannot read item" do
		assert ItemAuthorizer.readable_by?(@user1), "User 1 must have read access"
		@user1.revoke :event_user
		assert_not ItemAuthorizer.readable_by?(@user1), "User 1 must not have read access after revocation of event user role"
	end

	test "event user can update item" do
		assert ItemAuthorizer.updatable_by?(@organizer), "Organizer must have update access"
		assert ItemAuthorizer.updatable_by?(@user1), "User 1 must have update access"
	end

	test "user without event user role cannot update item" do
		assert ItemAuthorizer.updatable_by?(@user1), "User 1 must have update access"
		@user1.revoke :event_user
		assert_not ItemAuthorizer.updatable_by?(@user1), "User 1 must not have update access after revocation of event user role"
	end

	test "event user can delete item" do
		assert ItemAuthorizer.deletable_by?(@organizer), "Organizer must have delete access"
		assert ItemAuthorizer.deletable_by?(@user1), "User 1 must have delete access"
	end

	test "user without event user role cannot delete item" do
		assert ItemAuthorizer.deletable_by?(@user1), "User 1 must have delete access"
		@user1.revoke :event_user
		assert_not ItemAuthorizer.deletable_by?(@user1), "User 1 must not have delete access after revocation of event user role"
	end


	#Test instance level authorization (review event_user, event_participant, item_owner)

	test "roles initilization at item creation" do
		assert @organizer.has_role?(:event_participant, @item1), "Initializing organizer's items accesses for testing"
		assert @organizer.has_role?(:event_participant, @item2), "Initializing organizer's items accesses for testing"
		assert @organizer.has_role?(:event_participant, @item3), "Initializing organizer's items accesses for testing"
		assert @organizer.has_role?(:event_participant, @item4), "Initializing organizer's items accesses for testing"
		assert @organizer.has_role?(:event_participant, @item5), "Initializing organizer's items accesses for testing"
		assert @organizer.has_role?(:event_participant, @item6), "Initializing organizer's items accesses for testing"
		assert @user2.has_role?(:event_participant, @item1), "Initializing user's items accesses for testing"
		assert @user2.has_role?(:event_participant, @item2), "Initializing user's items accesses for testing"
		assert @user2.has_role?(:event_participant, @item3), "Initializing user's items accesses for testing"
		assert @user2.has_role?(:event_participant, @item4), "Initializing user's items accesses for testing"
		assert @user2.has_role?(:event_participant, @item5), "Initializing user's items accesses for testing"
		assert @user2.has_role?(:event_participant, @item6), "Initializing user's items accesses for testing"
	end

	test "revoke roles when item is destroyed" do
		@item1.destroy
		assert_not @organizer.has_role?(:event_participant, @item1), "Organizer must have his access revoked for item"
		assert_not @user1.has_role?(:event_participant, @item1), "User1 must have his access revoked for item"
		assert_not @user2.has_role?(:event_participant, @item1), "User2 must have his access revoked for item"
		assert_not @user3.has_role?(:event_participant, @item1), "User3 must have his access revoked for item"
		assert_not @user4.has_role?(:event_participant, @item1), "User4 must have his access revoked for item"
		assert_not @user5.has_role?(:event_participant, @item1), "User5 must have his access revoked for item"
	end

	test "initilialize role for a new participant" do
		@item1.initialize_role_for @non_participant_user
		assert @non_participant_user.has_role?(:event_participant, @item1), "New participant must have event participant authorization for item"
	end

	test "event participants can create item instance" do
		assert @item1.authorizer.creatable_by?(@organizer, @item1.event), "Organizer is event participant and must have create access"
		assert @item1.authorizer.creatable_by?(@user1, @item1.event), "User1 is event participant and must have create access"
	end

	test "non event participants cannot create item instance" do
		assert_not @item1.authorizer.creatable_by?(@non_participant_user, @item1.event), "Non participant must create access"
	end

	test "event participants can read item instance" do
		assert @item1.authorizer.readable_by?(@organizer, @event), "Organizer is item owner and must have read access"
		assert @item1.authorizer.readable_by?(@user1, @event), "User1 is beneficiary and must have read access"
		assert @item4.authorizer.readable_by?(@user2, @event), "User2, although not beneficiary, is event participant and must have read access"
	end

	test "event user cannot read item instance" do
		assert_not @item1.authorizer.readable_by?(@non_participant_user, @event), "Non participant must not have read access"
	end

	test "item owner can update item instance" do
		assert @item1.authorizer.updatable_by?(@organizer), "Organizer is item owner and must have write access"
	end

	test "non item owners cannot update item instance" do
		assert_not @item1.authorizer.updatable_by?(@user1), "User1 is not item owner and must not have updated access"
		assert_not @item1.authorizer.updatable_by?(@non_participant_user), "User is not event participant and must not have update access"
	end

	test "item owner can delete item instance" do
		assert @item1.authorizer.deletable_by?(@organizer), "Organizer is item owner and must have write access"
	end

	test "non item owners cannot delete item instance" do
		assert_not @item1.authorizer.deletable_by?(@user1), "User1 is not item owner and must not have delete access"
		assert_not @item1.authorizer.deletable_by?(@non_participant_user), "User is not event participant and must not have delete access"
	end
	
end 