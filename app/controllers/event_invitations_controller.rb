class EventInvitationsController < Devise::InvitationsController
  
	def new
		self.resource = resource_class.new(:event_id => params[:event_id])
	  render :new
	end

	def create
		event = Event.find(params[:user][:event_id])
		user = User.where(email: params[:user][:email].downcase)
		#candidate for refactoring: put logic into User model
		if user.exists? then
			invitee = user.first
			if event.add_participant invitee
				flash[:notice] = "#{invitee.name} had been added to the event"
			else
				flash[:notice] = "#{invitee.name} is already participant of event or pending invitation"
			end
			redirect_to events_path
		else
			super
		end	
	end

end