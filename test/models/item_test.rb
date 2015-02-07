require 'test_helper'
require 'webmock/minitest'
require 'open-uri'

class ItemTest < ActiveSupport::TestCase

	#Test data initialized in test_helper.rb

	test "do not save item without name" do
		@item1.name = nil
		assert_not @item1.save
	end

	test "do not save item without description" do
		@item1.description = nil
		assert_not @item1.save
	end

	test "do not save item without value date" do
		@item1.value_date = nil
		assert_not @item1.save
	end

	test "do not save item without event" do
		@item1.event = nil
		assert_not @item1.save
	end

	test "do not save item without base amount" do
		@item1.base_amount = nil
		assert_not @item1.save
	end

	test "do not save item without base currency" do
		@item1.base_currency = nil
		assert_not @item1.save
	end

	test "do not save item without exchange rate" do
		@item1.exchange_rate = nil
		assert_not @item1.save
	end

	test "do not save item without foreign amount" do
		@item1.foreign_amount = nil
		assert_not @item1.save
	end

	test "do not save item without foreign currency" do
		@item1.foreign_currency = nil
		assert_not @item1.save
	end

	test "do not save item without payer" do
		@item1.payer_id = nil
		assert_not @item1.save
	end

	test "do not save item without beneficiaries" do
		@item1.beneficiaries = nil
		assert_not @item1.save
	end

	test "base amount must be positive" do
		@item1.base_amount = -1
		assert_not @item1.save
	end

	test "exchange rate mus be positive" do
		@item1.exchange_rate = -1
		assert_not @item1.save
	end

	test "foreign amount must be positive" do
		@item1.foreign_amount = -1
		assert_not @item1.save
	end

	test "item's cost per beneficiary" do
		assert_equal 40.22, @item1.cost_per_beneficiary.round(2)
		assert_equal 11.17, @item2.cost_per_beneficiary.round(2)
		assert_equal 11.17, @item3.cost_per_beneficiary.round(2)
		assert_equal 36.87, @item4.cost_per_beneficiary.round(2)
		assert_equal 24.58, @item5.cost_per_beneficiary.round(2)
		assert_equal  1.79, @item6.cost_per_beneficiary.round(2)
	end

	test "apply exchange rate on item successfully" do
		stub_request(:get, "http://devel.farebookings.com/api/curconversor/DKK/EUR/1/json").to_return(:status => 200, :body => '{"EUR": 0.1343}')
		@item1.apply_exchange_rate
		assert_equal 0.1343, @item1.exchange_rate
		assert_equal 0.1343*@item1.foreign_amount, @item1.base_amount
	end

	test "time out error when requesting exchange rate for item" do
		stub_request(:any, "http://devel.farebookings.com/api/curconversor/DKK/EUR/1/json").to_raise(Timeout::Error)
		@item1.apply_exchange_rate
		assert_equal 1, @item1.errors[:exchange_rate].length
	end

	test "connection error when requesting exchange rate for item" do
		stub_request(:any, "http://devel.farebookings.com/api/curconversor/DKK/EUR/1/json").to_raise(OpenURI::HTTPError.new(nil, ""))
		@item1.apply_exchange_rate
		assert_equal 1, @item1.errors[:exchange_rate].length
	end

end 