module ApplicationHelper


	# Money constructor expects amount in subunit
	def money_format amount, currency
		Money.new(amount * Money::Currency.new(currency).subunit_to_unit, currency).format
	end

end
