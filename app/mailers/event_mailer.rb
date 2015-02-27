class EventMailer < ApplicationMailer

	helper :application

	# event invitation email
	def invitation_message event, participant
		@event = event
		@participant = participant
		mail(to: @participant.email_addressing, subject: "You have been invited to event " + @event.name)
	end

	# item creation email
	def item_created_message item
		setup_message item, "A new item has been posted: " + item.name + " in event " + item.event.name
	end

	# item modification email
	def item_modified_message item
		setup_message item, "Item " + item.name + " in event " + item.event.name + " was modified"
	end

	# item deletion email
	def item_deleted_message item
		setup_message item, "Item " + item.name + " in event " + item.event.name + " was deleted"
	end

	private

	def setup_message item, subject
		@item = item
		emails = []
		@item.beneficiaries.each do |participant|
			@participant = participant
			emails << participant.email_addressing		
		end
		mail(to: emails, subject: subject)
	end

end
