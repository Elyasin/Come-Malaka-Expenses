require 'test_helper'

class EventTest < ActiveSupport::TestCase

	#Test data initialized in test_helper.rb#setup
	#and truncated while teardown

	test "do not save event without name" do
		@event.name = nil
		assert_not @event.save, "Event must have name"
	end

	test "do not save event without From Date" do
		@event.from_date = nil
		assert_not @event.save, "Event must have a start date"
	end

	test "do not save event without To Date" do
		@event.to_date = nil
		assert_not @event.save, "Event must have an end date"
	end

	test "do not save event without description" do
		@event.description = nil
		assert_not @event.save, "Event must have a description"
	end

	test "do not save event without currency" do
		@event.event_currency = nil
		assert_not @event.save, "Event currency must be set"
	end

	test "do not save event without organizer" do
		@event.organizer_id = nil
		assert_not @event.save, "Event must have an organizer"
	end

	test "add new participant to event" do
		expected_size = @event.users.length + 1
		expected_users = @event.users << @non_participant_user
		@event.add_participant(@non_participant_user)
		assert_equal expected_users, @event.users, "New user must be event particpant"
		assert_equal expected_size, @event.users.length, "New user must be event particpant"
		assert_includes @event.users, @non_participant_user, "New user must be event particpant"
		assert @non_participant_user.has_role?(:event_participant, @event), "New user must be event particpant"
	end

	test "add already existing participant to event" do
		expected_size = @event.users.length
		expected_users = @event.users
		@event.add_participant(@organizer)
		assert_equal expected_users, @event.users, "Adding existing participant must not have any effect"
		assert_equal expected_size, @event.users.length, "Adding existing participant must not have any effect"
	end

	test "organizer's name" do
		assert_equal @organizer.name, @event.organizer, "Event must return organizer's name (or alternatively email)"
	end

	test "paid expense items by participants" do
		assert_equal 5, @event.paid_expense_items_by(@organizer).length, "Organizer paid 5 items"
		assert_equal 0, @event.paid_expense_items_by(@user1).length, "User 1 did not pay any item"
		assert_equal 0, @event.paid_expense_items_by(@user2).length, "User 2 did not pay any item"
		assert_equal 0, @event.paid_expense_items_by(@user3).length, "User 3 did not pay any item"
		assert_equal 1, @event.paid_expense_items_by(@user4).length, "User 4 paid 1 item"
		assert_equal 0, @event.paid_expense_items_by(@user5).length, "User 5 did not pay any item"
	end

	test "total expense amount for participants" do
		assert_equal 670.28, @event.total_expenses_amount_for(@organizer).round(2), "Organizer spent on many items 670.28"
		assert_equal 0, @event.total_expenses_amount_for(@user1).round(2), "User 1 did not spend anything"
		assert_equal 0, @event.total_expenses_amount_for(@user2).round(2), "User 2 did not spend anything"
		assert_equal 0, @event.total_expenses_amount_for(@user3).round(2), "User 3 did not spend anything"
		assert_equal 10.72, @event.total_expenses_amount_for(@user4).round(2), "User 4 spent on one item 10.72"
		assert_equal 0, @event.total_expenses_amount_for(@user5).round(2), "User 5 did not spend anything"
	end

	test "total benefited amount for participants" do
		assert_equal 125.79, @event.total_benefited_amount_for(@organizer).round(2), "Organizer benefited from 125.79"
		assert_equal 125.79, @event.total_benefited_amount_for(@user1).round(2), "User 1 benefited from 125.79"
		assert_equal 88.92, @event.total_benefited_amount_for(@user2).round(2), "User 2 benefited from 88.92"
		assert_equal 125.79, @event.total_benefited_amount_for(@user3).round(2), "User 3 benefited from 125.79"
		assert_equal 125.79, @event.total_benefited_amount_for(@user4).round(2), "User 4 benefited from 125.79"
		assert_equal 88.92, @event.total_benefited_amount_for(@user5).round(2), "User 5 benefited from 88.92"
	end

	test "balance for participant" do
		assert_equal 544.49, @event.balance_for(@organizer).round(2), "Organizer must receive 544.49"
		assert_equal -125.79, @event.balance_for(@user1).round(2), "User 1 must pay 125.79"
		assert_equal -88.92, @event.balance_for(@user2).round(2), "User 2 must pay 88.92"
		assert_equal -125.79, @event.balance_for(@user3).round(2), "User 3 must pay 125.79"
		assert_equal -115.07, @event.balance_for(@user4).round(2), "User 4 must pay 88.92"
		assert_equal -88.92, @event.balance_for(@user5).round(2), "User 5 must pay 125.79"
	end


	#Test classe level authorization

	test "event user role can create event" do
		assert EventAuthorizer.creatable_by?(@organizer), "Organizer must have create access"
		assert EventAuthorizer.creatable_by?(@user1), "User 1 must have create access"
	end

	test "user without event user role cannot create event" do
		assert EventAuthorizer.creatable_by?(@user1), "User 1 must have create access"
		@user1.revoke :event_user
		assert_not EventAuthorizer.creatable_by?(@user1), "User 1 must not have create access after revocation of event user role"
	end

	test "event user can read event" do
		assert EventAuthorizer.readable_by?(@organizer), "Organizer must have read access"
		assert EventAuthorizer.readable_by?(@user1), "User 1 must have read access"
	end

	test "user without event user role cannot read event" do
		assert EventAuthorizer.readable_by?(@user1), "User 1 must have read access"
		@user1.revoke :event_user
		assert_not EventAuthorizer.readable_by?(@user1), "User 1 must not have read access after revocation of event user role"
	end

	test "event user can update event" do
		assert EventAuthorizer.updatable_by?(@organizer), "Organizer must have update access"
		assert EventAuthorizer.updatable_by?(@user1), "User 1 must have update access"
	end

	test "user without event user role cannot update event" do
		assert EventAuthorizer.updatable_by?(@user1), "User 1 must have update access"
		@user1.revoke :event_user
		assert_not EventAuthorizer.updatable_by?(@user1), "User 1 must not have update access after revocation of event user role"
	end

	test "event user can delete event" do
		assert EventAuthorizer.deletable_by?(@organizer), "Organizer must have delete access"
		assert EventAuthorizer.deletable_by?(@user1), "User 1 must have delete access"
	end

	test "user without event user role cannot delete event" do
		assert EventAuthorizer.deletable_by?(@user1), "User 1 must have delete access"
		@user1.revoke :event_user
		assert_not EventAuthorizer.deletable_by?(@user1), "User 1 must not have delete access after revocation of event user role"
	end


	#Test instance level authorization (review event_user, event_participant, item_owner)

	test "event users can create event instance" do
		assert @event.authorizer.creatable_by?(@organizer), "Organizer must have create instance access"
		assert @event.authorizer.creatable_by?(@non_participant_user), "Non participant must have create instance access"
	end

	test "event participant can read event instance" do
		assert @event.authorizer.readable_by?(@organizer), "Organizer must have read instance access"
	end

	test "event user cannot read event instance" do
		assert_not @event.authorizer.readable_by?(@non_participant_user), "Non participant must not have read instance"
	end

	test "event organizer can update event instance" do
		assert @event.authorizer.updatable_by?(@organizer), "Organizer must have update instance access"
	end

	test "event participant cannot update event instance" do
		assert_not @event.authorizer.updatable_by?(@user1), "Event participant (non organizer) must not have update instance access"
	end

	test "event user cannot update event instance" do
		assert_not @event.authorizer.updatable_by?(@non_participant_user), "Non participant must not have update instance access"
	end

	test "event organizer can delete event instance" do
		assert @event.authorizer.deletable_by?(@organizer), "Organizer must have delete instance access"
	end

	test "event participant cannot delete event instance" do
		assert_not @event.authorizer.deletable_by?(@user1), "Event participant (non organizer) must not have delete instance access"
	end

	test "event user cannot delete event instance" do
		assert_not @event.authorizer.deletable_by?(@non_participant_user), "Non participant must not have delete instance access"
	end

end
