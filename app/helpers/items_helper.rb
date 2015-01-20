module ItemsHelper

def select_currency item, event
	item.foreign_currency.nil? ? event.event_currency : item.foreign_currency
end

end