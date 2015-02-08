require 'test_helper'

class EventTest < ActiveSupport::TestCase

	#Test data initialized in test_helper.rb#setup
	#and truncated while teardown

	test "do not save event without name" do
		@event.name = nil
		assert_not @event.save
	end

	test "do not save event without From Date" do
		@event.from_date = nil
		assert_not @event.save
	end

	test "do not save event without To Date" do
		@event.to_date = nil
		assert_not @event.save
	end

	test "do not save event without description" do
		@event.description = nil
		assert_not @event.save
	end

	test "do not save event without currency" do
		@event.event_currency = nil
		assert_not @event.save
	end

	test "do not save event without organizer" do
		@event.organizer_id = nil
		assert_not @event.save
	end

	test "add new participant to event" do
		expected_size = @event.users.length + 1
		expected_users = @event.users << @non_participant_user
		@event.add_participant(@non_participant_user)
		assert_equal expected_users, @event.users
		assert_equal expected_size, @event.users.length
		assert_includes @event.users, @non_participant_user
		assert @non_participant_user.has_role?(:event_participant, @event)
	end

	test "add already existing participant to event" do
		expected_size = @event.users.length
		expected_users = @event.users
		@event.add_participant(@organizer)
		assert_equal expected_users, @event.users
		assert_equal expected_size, @event.users.length
	end

	test "organizer's name" do
		assert_equal @organizer.name, @event.organizer
	end

	test "paid expense items by participants" do
		assert_equal(5, @event.paid_expense_items_by(@organizer).length)
		assert_equal(0, @event.paid_expense_items_by(@user1).length)
		assert_equal(0, @event.paid_expense_items_by(@user2).length)
		assert_equal(0, @event.paid_expense_items_by(@user3).length)
		assert_equal(1, @event.paid_expense_items_by(@user4).length)
		assert_equal(0, @event.paid_expense_items_by(@user5).length)
	end

	test "total expense amount for participants" do
		assert_equal(670.28, @event.total_expenses_amount_for(@organizer).round(2))
		assert_equal(0, @event.total_expenses_amount_for(@user1).round(2))
		assert_equal(0, @event.total_expenses_amount_for(@user2).round(2))
		assert_equal(0, @event.total_expenses_amount_for(@user3).round(2))
		assert_equal(10.72, @event.total_expenses_amount_for(@user4).round(2))
		assert_equal(0, @event.total_expenses_amount_for(@user5).round(2))
	end

	test "total benefited amount for participants" do
		assert_equal(125.79, @event.total_benefited_amount_for(@organizer).round(2))
		assert_equal(125.79, @event.total_benefited_amount_for(@user1).round(2))
		assert_equal(88.92, @event.total_benefited_amount_for(@user2).round(2))
		assert_equal(125.79, @event.total_benefited_amount_for(@user3).round(2))
		assert_equal(125.79, @event.total_benefited_amount_for(@user4).round(2))
		assert_equal(88.92, @event.total_benefited_amount_for(@user5).round(2))
	end

	test "balance for participant" do
		assert_equal(544.49, @event.balance_for(@organizer).round(2))
		assert_equal(-125.79, @event.balance_for(@user1).round(2))
		assert_equal(-88.92, @event.balance_for(@user2).round(2))
		assert_equal(-125.79, @event.balance_for(@user3).round(2))
		assert_equal(-115.07, @event.balance_for(@user4).round(2))
		assert_equal(-88.92, @event.balance_for(@user5).round(2))
	end


	#Test classe level authorization

	test "event user role can create event" do
		assert EventAuthorizer.creatable_by?(@organizer)
		assert EventAuthorizer.creatable_by?(@user1)
	end

	test "user without event user role cannot create event" do
		assert EventAuthorizer.creatable_by?(@user1)
		@user1.revoke :event_user
		assert_not EventAuthorizer.creatable_by?(@user1)
	end

	test "event user can read event" do
		assert EventAuthorizer.readable_by?(@organizer)
		assert EventAuthorizer.readable_by?(@user1)
	end

	test "user without event user role cannot read event" do
		assert EventAuthorizer.readable_by?(@user1)
		@user1.revoke :event_user
		assert_not EventAuthorizer.readable_by?(@user1)
	end

	test "event user can update event" do
		assert EventAuthorizer.updatable_by?(@organizer)
		assert EventAuthorizer.updatable_by?(@user1)
	end

	test "user without event user role cannot update event" do
		assert EventAuthorizer.updatable_by?(@user1)
		@user1.revoke :event_user
		assert_not EventAuthorizer.updatable_by?(@user1)
	end

	test "event user can delete event" do
		assert EventAuthorizer.deletable_by?(@organizer)
		assert EventAuthorizer.deletable_by?(@user1)
	end

	test "user without event user role cannot delete event" do
		assert EventAuthorizer.deletable_by?(@user1)
		@user1.revoke :event_user
		assert_not EventAuthorizer.deletable_by?(@user1)
	end


	#Test instance level authorization (review event_user, event_participant, item_owner)

	test "event users can create event instance" do
		assert @event.authorizer.creatable_by?(@organizer)
		assert @event.authorizer.creatable_by?(@non_participant_user)
	end

	test "event participant can read event instance" do
		assert @event.authorizer.readable_by?(@organizer)
	end

	test "event user cannot read event instance" do
		assert_not @event.authorizer.readable_by?(@non_participant_user)
	end

	test "event organizer can update event instance" do
		assert @event.authorizer.updatable_by?(@organizer)
	end

	test "event participant cannot update event instance" do
		assert_not @event.authorizer.updatable_by?(@user1)
	end

	test "event user cannot update event instance" do
		assert_not @event.authorizer.updatable_by?(@non_participant_user)
	end

	test "event organizer can delete event instance" do
		assert @event.authorizer.deletable_by?(@organizer)
	end

	test "event participant cannot delete event instance" do
		assert_not @event.authorizer.deletable_by?(@user1)
	end

	test "event user cannot delete event instance" do
		assert_not @event.authorizer.deletable_by?(@non_participant_user)
	end

end
