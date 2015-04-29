require 'test_helper'

class ItemsHelperTest < ActionView::TestCase
	include ItemsHelper

	test "no foreign currency in item: return event currency" do
		assert_equal "DKK", select_currency(@item1, @event)
	end

	test "foreign currency in item is nil: return item's foreign currency" do
		@item1.foreign_currency = nil
		assert_equal "EUR", select_currency(@item1, @event)
	end

	test "foreign currency in item is empty string: return item's foreign currency" do
		@item1.foreign_currency = ""
		assert_equal "EUR", select_currency(@item1, @event)
	end		
end