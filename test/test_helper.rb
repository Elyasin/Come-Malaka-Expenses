require "codeclimate-test-reporter"
CodeClimate::TestReporter.start
require 'simplecov'
SimpleCov.start 'rails' do
	add_group 'Views', 'app/views'
	add_group 'Authorizers', 'app/authorizers'
  formatter SimpleCov::Formatter::MultiFormatter[
    SimpleCov::Formatter::HTMLFormatter,
    CodeClimate::TestReporter::Formatter
  ]
end
ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'minitest/autorun'
require 'database_cleaner'

DatabaseCleaner[:mongoid].strategy = :truncation

#CodeClimate reporting must not be blocked by WebMock
WebMock.disable_net_connect!(:allow => "codeclimate.com")

class ActiveSupport::TestCase
  # Add more helper methods to be used by all tests here...


  #Mongoid does not support fixtures :-(
  #Setting up more realistic test data of first Come Malaka event
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
		@non_participant_user = User.create!(first_name: "Javier", last_name: "Ductor", email: "user6@event.com", password: "user6789")
		@non_participant_user.save!
		@event = Event.new(name: "Randers", from_date: Date.new(2012, 11, 2), 
			end_date: Date.new(2012, 11, 4), description: "Come Malaka event in Denmark", 
			event_currency: "EUR", organizer: @organizer)
		@event.add_participant(@organizer)
		@event.add_participant(@user1)
		@event.add_participant(@user2)
		@event.add_participant(@user3)
		@event.add_participant(@user4)
		@event.add_participant(@user5)
		@event.save!
		@item1 = Item.new(name: "Food", description: "Food", value_date: @event.from_date, 
			event: @event, base_amount: 241.3, base_currency: "EUR", 
			exchange_rate: 241.3.to_d/1800, foreign_amount: 1800, foreign_currency: "DKK", 
			payer: @organizer, beneficiaries: [@organizer, @user1, @user2, @user3, @user4, @user5])
		@item1.initialize_roles
		@item1.save!
		@item2 = Item.new(name: "Gas", description: "Gas", value_date: @event.from_date, 
			event: @event, base_amount: 67.03, base_currency: "EUR", 
			exchange_rate: 67.03.to_d/500, foreign_amount: 500, foreign_currency: "DKK", 
			payer: @organizer, beneficiaries: [@organizer, @user1, @user2, @user3, @user4, @user5])
		@item2.initialize_roles
		@item2.save!
		@item3 = Item.new(name: "Drinks", description: "Drinks", value_date: @event.from_date, 
			event: @event, base_amount: 67.03, base_currency: "EUR", 
			exchange_rate: 67.03.to_d/500, foreign_amount: 500, foreign_currency: "DKK", 
			payer: @organizer, beneficiaries: [@organizer, @user1, @user2, @user3, @user4, @user5])
		@item3.initialize_roles
		@item3.save!
		@item4 = Item.new(name: "Night out", description: "Night out & Misc", value_date: @event.from_date, 
			event: @event, base_amount: 147.46, base_currency: "EUR", 
			exchange_rate: 147.46.to_d/1100, foreign_amount: 1100, foreign_currency: "DKK", 
			payer: @organizer, beneficiaries: [@organizer, @user1, @user3, @user4])
		@item4.initialize_roles
		@item4.save!
		@item5 = Item.new(name: "Night out", description: "Night out & Misc", value_date: @event.from_date+1, 
			event: @event, base_amount: 147.46, base_currency: "EUR", 
			exchange_rate: 147.46.to_d/1100, foreign_amount: 1100, foreign_currency: "DKK", 
			payer: @organizer, beneficiaries: [@organizer, @user1, @user2, @user3, @user4, @user5])
		@item5.initialize_roles
		@item5.save!
		@item6 = Item.new(name: "Taxi", description: "Taxi", value_date: @event.from_date+1, 
			event: @event, base_amount: 10.72, base_currency: "EUR", 
			exchange_rate: 10.72.to_d/80, foreign_amount: 80, foreign_currency: "DKK", 
			payer: @user4, beneficiaries: [@organizer, @user1, @user2, @user3, @user4, @user5])
		@item6.initialize_roles
		@item6.save!
	end

	def teardown
		DatabaseCleaner.clean
	end

end

#inlcude Devise test helpers
class ActionController::TestCase
	include Devise::TestHelpers
end