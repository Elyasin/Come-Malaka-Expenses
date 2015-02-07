require 'test_helper'

class EventTest < ActiveSupport::TestCase

	#Test data initialized in test_helper.rb

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
		new_user = User.create!(first_name: "Javier", last_name: "Ductor", email: "user6@event.com", password: "user6789")
		expected_size = @event.users.length + 1
		expected_users = @event.users << new_user
		@event.add_participant(new_user)
		assert_equal expected_users, @event.users
		assert_equal expected_size, @event.users.length
		assert_includes @event.users, new_user
		assert new_user.has_role?(:event_participant, @event)
		assert new_user.has_role?(:event_participant, Event)
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

end
