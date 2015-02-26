class EventMailer < ApplicationMailer

	helper :application

	# event invitation email
	def invitation_message event, participant
		@event = event
		@participant = participant
		email = (@participant.name.blank? ? @participant.email : %("#{@participant.name}" <#{@participant.email}>))
		mail(to: email, subject: "You have been invited to event " + @event.name)
	end

	# item creation email
	def item_created_message item
		@item = item
		emails = []
		@item.beneficiaries.each do |participant|
			@participant = participant
			emails << @participant.name			
		end
		mail(to: emails, subject: "A new item has been posted: " + @item.name + " in event " + @item.event.name)
	end

	# item modification email
	def item_modified_message item
		@item = item
		emails = []
		@item.beneficiaries.each do |participant|
			@participant = participant
			emails << @participant.name			
		end
		mail(to: emails, subject: "Item " + @item.name + " in event " + @item.event.name + " was modified")
	end

	# item deletion email
	def item_deleted_message item
		@item = item
		emails = []
		@item.beneficiaries.each do |participant|
			@participant = participant
			emails << @participant.name			
		end
		mail(to: emails, subject: "Item " + @item.name + " in event " + @item.event.name + " was deleted")		
	end

end
