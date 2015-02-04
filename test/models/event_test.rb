require 'test_helper'

class EventTest < ActiveSupport::TestCase

	def setup
		@organizer = User.new(first_name: "Lasse", last_name: "Lund", email: "organizer@event.com", password: "organizer")
		@organizer.save!
		@user1 = User.new(first_name: "Elyasin", last_name: "Shaladi", email: "user1@event.com", password: "user1234")
		@user1.save!
		@user2 = User.new(first_name: "Theo", last_name: "Goumas", email: "user2@event.com", password: "user2345")
		@user2.save!
		@user3 = User.new(first_name: "Nuno", last_name: "Fonseca", email: "user3@event.com", password: "user3456")
		@user3.save!
		@user4 = User.new(first_name: "Juan", last_name: "Cabrera", email: "user4@event.com", password: "user4567")
		@user4.save!
		@user5 = User.new(first_name: "Neal", last_name: "Mundy", email: "user5@event.com", password: "user5678")
		@user5.save!
		@event = Event.new(name: "Randers", from_date: Date.new(2012, 11, 2), 
			to_date: Date.new(2012, 11, 4), description: "Come Malaka event in Denmark", 
			event_currency: Money::Currency.new(:eur), users: [@organizer, @user1, @user2, @user3, @user4, @user5], 
			organizer_id: @organizer.id)
		@event.save!
		@item1 = Item.new(name: "Food", description: "Food", value_date: @event.from_date, 
			event: @event, base_amount: 241.3, base_currency: Money::Currency.new(:eur), 
			exchange_rate: 241.3/1800.to_d, foreign_amount: 1800, foreign_currency: Money::Currency.new(:dkk), 
			payer_id: @organizer.id, beneficiaries: [@organizer, @user1, @user2, @user3, @user4, @user5])
		@item1.save!
		@item2 = Item.new(name: "Gas", description: "Gas", value_date: @event.from_date, 
			event: @event, base_amount: 67.03, base_currency: Money::Currency.new(:eur), 
			exchange_rate: 67.03/500.to_d, foreign_amount: 500, foreign_currency: Money::Currency.new(:dkk), 
			payer_id: @organizer.id, beneficiaries: [@organizer, @user1, @user2, @user3, @user4, @user5])
		@item2.save!
		@item3 = Item.new(name: "Drinks", description: "Drinks", value_date: @event.from_date, 
			event: @event, base_amount: 67.03, base_currency: Money::Currency.new(:eur), 
			exchange_rate: 67.03/500.to_d, foreign_amount: 500, foreign_currency: Money::Currency.new(:dkk), 
			payer_id: @organizer.id, beneficiaries: [@organizer, @user1, @user2, @user3, @user4, @user5])
		@item3.save!
		@item4 = Item.new(name: "Night out", description: "Night out & Misc", value_date: @event.from_date, 
			event: @event, base_amount: 147.46, base_currency: Money::Currency.new(:eur), 
			exchange_rate: 147.46/1100.to_d, foreign_amount: 1100, foreign_currency: Money::Currency.new(:dkk), 
			payer_id: @organizer.id, beneficiaries: [@organizer, @user1, @user3, @user4])
		@item4.save!
		@item5 = Item.new(name: "Night out", description: "Night out & Misc", value_date: @event.from_date+1, 
			event: @event, base_amount: 147.46, base_currency: Money::Currency.new(:eur), 
			exchange_rate: 147.46/1100.to_d, foreign_amount: 1100, foreign_currency: Money::Currency.new(:dkk), 
			payer_id: @organizer.id, beneficiaries: [@organizer, @user1, @user2, @user3, @user4, @user5])
		@item5.save!
		@item6 = Item.new(name: "Taxi", description: "Taxi", value_date: @event.from_date+1, 
			event: @event, base_amount: 10.72, base_currency: Money::Currency.new(:eur), 
			exchange_rate: 10.72/80.to_d, foreign_amount: 80, foreign_currency: Money::Currency.new(:dkk), 
			payer_id: @user4.id, beneficiaries: [@organizer, @user1, @user2, @user3, @user4, @user5])
		@item6.save!
	end

	def teardown
		@organizer.destroy!
		@user1.destroy!
		@user2.destroy!
		@user3.destroy!
		@user4.destroy!
		@user5.destroy!
		@event.destroy!
		@item1.destroy!
		@item2.destroy!
		@item3.destroy!
		@item5.destroy!
		@item6.destroy!
	end

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
		u = User.new(first_name: "Agent", last_name: "Unknown")
		assert @event.add_participant u
	end

	test "add already existing participant to event" do
		assert_not @event.add_participant @organizer
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
