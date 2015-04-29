require 'test_helper'

class ApplicationHelperTest < ActionView::TestCase
	include ApplicationHelper

	def setup
		@amount = 100.to_d
	end

	def teardown
		@amount = nil
	end

	test "money format for Euro" do
		currency = :eur
		assert_equal "€100.00", money_format(@amount,currency)
	end

	test "money format for US dollar" do
		currency = :usd
		assert_equal "$100.00", money_format(@amount, currency)
	end
end
