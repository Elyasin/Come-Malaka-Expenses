class EventInvitationsRoutesTest < ActionController::TestCase

  test "must route to new event invitation" do
    assert_routing 'events/88/invite', controller: "event_invitations", action: "new", event_id: "88"
  end

end