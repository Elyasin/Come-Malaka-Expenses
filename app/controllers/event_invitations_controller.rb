class EventInvitationsController < Devise::InvitationsController
  
	def new
		@event = Event.find(params[:event_id])
		self.resource = resource_class.new(:event_id => @event.id)
	  render :new
	end

	def create
		@event = Event.find(params[:user][:event_id])
		user = User.where(email: params[:user][:email].downcase)

		if user.exists? then
			@invitee = user.first
			if @event.add_participant(@invitee)
				flash[:notice] = "#{@invitee.name} had been added to the event."
				EventMailer.invitation_message(@event, @invitee).deliver_now
			else
				flash[:notice] = "#{@invitee.name} is already participant of event or pending invitation acceptance."
			end
			redirect_to events_path
		else
			super
		end	
	end

end