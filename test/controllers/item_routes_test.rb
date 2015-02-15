class ItemRoutesTest < ActionController::TestCase

  test "must route to item index" do
    assert_routing 'events/88/items', controller: "items", action: "index", event_id: "88"
  end
 
  test "must route to item show" do
    assert_routing '/items/15', controller: "items", action: "show", id: "15"
  end

	test "must route to new item" do
		assert_routing 'events/44/items/new', controller: "items", action: "new", event_id: "44"
	end

	test "must route to create item" do
		assert_routing({ method: 'post', path: 'events/33/items' }, { controller: "items", action: "create", event_id: "33"})
	end

	test "must route to edit item" do
		assert_routing 'items/19/edit', controller: "items", action: "edit", id: "19"
	end

	test "must update to update item" do
		assert_routing({ method: 'put', path: 'items/98' }, { controller: "items", action: "update", id: "98"})
		assert_routing({ method: 'patch', path: 'items/98' }, { controller: "items", action: "update", id: "98"})
	end

	test "must route to destroy item" do
		assert_routing({ method: 'delete', path: 'items/86' }, { controller: "items", action: "destroy", id: "86" } )
	end



end