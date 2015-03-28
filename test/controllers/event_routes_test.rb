class EventRoutesTest < ActionController::TestCase

  test "must route to event index" do
    assert_routing '/events', controller: "events", action: "index"
  end
 
  test "must route to event show" do
    assert_routing '/events/15', controller: "events", action: "show", id: "15"
  end

  test "must route to event all items" do
  	assert_routing 'event_items/12', controller: "events", action: "event_all_items", event_id: "12"
	end

	test "must route to expense report" do
		assert_routing 'expense_report/99', controller: "events", action: "expense_report", event_id: "99"
	end

	test "must route to new event" do
		assert_routing 'events/new', controller: "events", action: "new"
	end

	test "must route to create event" do
		assert_routing({ method: 'post', path: 'events' }, { controller: "events", action: "create" })
	end

	test "must route to edit event" do
		assert_routing 'events/19/edit', controller: "events", action: "edit", id: "19"
	end

	test "must update to update event" do
		assert_routing({ method: 'put', path: 'events/98' }, { controller: "events", action: "update", id: "98"})
		assert_routing({ method: 'patch', path: 'events/98' }, { controller: "events", action: "update", id: "98"})
	end

	test "must route to destroy event" do
		assert_routing({ method: 'delete', path: 'events/86' }, { controller: "events", action: "destroy", id: "86" } )
	end

	test "must route to 'who owes you?'" do
		assert_routing({ method: 'get', path: 'who_owes_you/100' }, {controller: "events", action: "who_owes_you", event_id: "100"} )
	end

end