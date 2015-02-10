require 'test_helper'

class UserTest < ActiveSupport::TestCase

	test "name returns first name (and last name) if first name is set" do
		assert_equal "Lasse Lund", @organizer.name, "Organizer's name must be Lasse Lund"
	end

	test "name returns email if first name is not set" do
		@user1.first_name = nil
		assert_equal "user1@event.com", @user1.name, "Organizer's email must be organizer@event.com"
	end

	test "new user is added as participant to invited event" do
		@non_participant_user.event = @event
		@non_participant_user.add_to_invited_event
		assert_nil @non_participant_user.event
		assert_includes @event.users, @non_participant_user, "Event users must contain newly added participant"
		assert @non_participant_user.has_role?(:event_participant, @event), "Newly added participant must have event instance access"
		assert @non_participant_user.has_role?(:event_user), "Newly added participant must still have event user role"

	end

	test "users have role :event_user role by default " do
		assert @organizer.has_role?(:event_user), "Organizer must have event user role"
		assert @user1.has_role?(:event_user), "User 1 must have event user role"
		assert @user2.has_role?(:event_user), "User 2 must have event user role"
		assert @user3.has_role?(:event_user), "User 3 must have event user role"
		assert @user4.has_role?(:event_user), "User 4 must have event user role"
		assert @user5.has_role?(:event_user), "User 5 must have event user role"
	end

	test "users do not have global :event_participant role by default" do
		assert_not @organizer.has_role?(:event_participant), "No user must have global event participant role"
		assert_not @user1.has_role?(:event_participant), "No user must have global event participant role"
		assert_not @user2.has_role?(:event_participant), "No user must have global event participant role"
		assert_not @user3.has_role?(:event_participant), "No user must have global event participant role"
		assert_not @user4.has_role?(:event_participant), "No user must have global event participant role"
		assert_not @user5.has_role?(:event_participant), "No user must have global event participant role"
	end

	test "users do not have global :item_owner role by default" do
		assert_not @organizer.has_role?(:item_owner), "No user must have global item owner role"
		assert_not @user1.has_role?(:item_owner), "No user must have global item owner role"
		assert_not @user2.has_role?(:item_owner), "No user must have global item owner role"
		assert_not @user3.has_role?(:item_owner), "No user must have global item owner role"
		assert_not @user4.has_role?(:item_owner), "No user must have global item owner role"
		assert_not @user5.has_role?(:item_owner), "No user must have global item owner role"
	end

end
