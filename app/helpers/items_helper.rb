module ItemsHelper

  # return item's foreign currency if not blank
  def select_currency item, event
    item.foreign_currency.blank? ? event.event_currency : item.foreign_currency
  end

end
