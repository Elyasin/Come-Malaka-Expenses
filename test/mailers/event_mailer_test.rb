require 'test_helper'

class EventMailerTest < ActionMailer::TestCase
		include Rails.application.routes.url_helpers

	test "send email to invitee when invited to event" do
		email = EventMailer.invitation_message(@event, @non_participant_user).deliver_now!
		assert_not ActionMailer::Base.deliveries.empty?
		assert_equal ['info@comemalaka.com'], email.from, "Sender email is not correct"
		assert_equal 'user6@event.com', email.to[0], "Recipient email is not correct"
		assert_equal "You have been invited to event " + @event.name, email.subject, "Email subject is incorrect"
		email_text = read_fixture('invitation_message').join.sub!("__EVENT_LINK__", event_url(@event, host: "localhost:3000"))
		assert_equal email_text, email.text_part.body.to_s, "Email body is incorrect"
	end

	test "send email to beneficiaries when item created" do
		email = EventMailer.item_created_message(@item1).deliver_now!
		assert_not ActionMailer::Base.deliveries.empty?
		assert_equal ['info@comemalaka.com'], email.from, "Sender email is not correct"
		assert_includes email.to, 'Lasse Lund', "Recipient email is not correct"
		assert_includes email.to, 'Elyasin Shaladi', "Recipient email is not correct"
		assert_includes email.to, 'Theo Goumas', "Recipient email is not correct"
		assert_includes email.to, 'Neal Mundy', "Recipient email is not correct"
		assert_includes email.to, 'Juan Cabrera', "Recipient email is not correct"
		assert_includes email.to, 'Nuno Fonseca', "Recipient email is not correct"
		assert_equal "A new item has been posted: " + @item1.name + " in event " + @item1.event.name, email.subject, "Email subject is incorrect"
		email_text = read_fixture('item_created_message').join.sub!("__ITEM_LINK__", item_url(@item1, host: "localhost:3000"))
		assert_equal email_text, email.text_part.body.to_s, "Email body is incorrect"
	end

	test "send email to beneficiaries when item modified" do
		email = EventMailer.item_modified_message(@item1).deliver_now!
		assert_not ActionMailer::Base.deliveries.empty?
		assert_equal ['info@comemalaka.com'], email.from, "Sender email is not correct"
		assert_includes email.to, 'Lasse Lund', "Recipient email is not correct"
		assert_includes email.to, 'Elyasin Shaladi', "Recipient email is not correct"
		assert_includes email.to, 'Theo Goumas', "Recipient email is not correct"
		assert_includes email.to, 'Neal Mundy', "Recipient email is not correct"
		assert_includes email.to, 'Juan Cabrera', "Recipient email is not correct"
		assert_includes email.to, 'Nuno Fonseca', "Recipient email is not correct"
		assert_equal "Item " + @item1.name + " in event " + @item1.event.name + " was modified", email.subject, "Email subject is incorrect"
		email_text = read_fixture('item_modified_message').join.sub!("__ITEM_LINK__", item_url(@item1, host: "localhost:3000"))
		assert_equal email_text, email.text_part.body.to_s, "Email body is incorrect"
	end

	test "send email to beneficiaries when item deleted" do
		email = EventMailer.item_deleted_message(@item1).deliver_now!
		assert_not ActionMailer::Base.deliveries.empty?
		assert_equal ['info@comemalaka.com'], email.from, "Sender email is not correct"
		assert_includes email.to, 'Lasse Lund', "Recipient email is not correct"
		assert_includes email.to, 'Elyasin Shaladi', "Recipient email is not correct"
		assert_includes email.to, 'Theo Goumas', "Recipient email is not correct"
		assert_includes email.to, 'Neal Mundy', "Recipient email is not correct"
		assert_includes email.to, 'Juan Cabrera', "Recipient email is not correct"
		assert_includes email.to, 'Nuno Fonseca', "Recipient email is not correct"
		assert_equal "Item " + @item1.name + " in event " + @item1.event.name + " was deleted", email.subject, "Email subject is incorrect"
		assert_equal read_fixture('item_deleted_message').join, email.text_part.body.to_s, "Email body is incorrect"
	end

end
