require 'test_helper'

class UserTest < ActiveSupport::TestCase

	test "name returns first name (and last name) if first name is set" do
		assert_equal "Lasse Lund", @organizer.name
	end

	test "name returns email if first name is not set" do
		@user1.first_name = nil
		assert_equal "user1@event.com", @user1.name
	end

	test "new user is added as participant to invited event" do
		new_user = User.create!(first_name: "Javier", last_name: "Ductor", email: "user6@event.com", password: "user6789", event_id: @event.id)
		expected_size = @event.users.length + 1
		expected_users = @event.users << new_user
		new_user.add_to_invited_event
		assert_equal expected_size, @event.users.length
		assert_equal expected_users, @event.users
		assert_includes @event.users, new_user
		assert new_user.has_role?(:event_participant, @event)
		assert new_user.has_role?(:event_participant, Event)
	end

end
