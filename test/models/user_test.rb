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
		@non_participant_user.event_id = @event.id
		expected_size = @event.users.length + 1
		expected_users = @event.users << @non_participant_user
		@non_participant_user.add_to_invited_event
		assert_equal expected_size, @event.users.length
		assert_equal expected_users, @event.users
		assert_includes @event.users, @non_participant_user
		assert @non_participant_user.has_role?(:event_participant, @event)
		assert @non_participant_user.has_role?(:event_user)
	end

	test "users have role :event_user role by default " do
		assert @organizer.has_role? :event_user
		assert @user1.has_role? :event_user
		assert @user2.has_role? :event_user
		assert @user3.has_role? :event_user
		assert @user4.has_role? :event_user
		assert @user5.has_role? :event_user
	end

	test "users do not have global :event_participant role by default" do
		assert_not @organizer.has_role? :event_participant
		assert_not @user1.has_role? :event_participant
		assert_not @user2.has_role? :event_participant
		assert_not @user3.has_role? :event_participant
		assert_not @user4.has_role? :event_participant
		assert_not @user5.has_role? :event_participant
	end

	test "users do not have global :item_owner role by default" do
		assert_not @organizer.has_role? :item_owner
		assert_not @user1.has_role? :item_owner
		assert_not @user2.has_role? :item_owner
		assert_not @user3.has_role? :item_owner
		assert_not @user4.has_role? :item_owner
		assert_not @user5.has_role? :item_owner
	end

end
