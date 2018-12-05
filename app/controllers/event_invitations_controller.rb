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
      if @event.contains @invitee then
        flash[:notice] = "#{@invitee.name} is already participant"
			elsif ((@invitee.invitation_token? and @invitee.invitation_accepted?) or 
                !@invitee.invitation_token?) and 
                @event.add_participant(@invitee) then
				flash[:notice] = "#{@invitee.name} had been added to the event."
				EventMailer.invitation_message(@event, @invitee).deliver_now
			else
				flash[:notice] = "#{@invitee.name} is pending invitation acceptance of an event."
			end
		  redirect_to events_path
		else # new user, so create one
			super
		end	
	end

end
