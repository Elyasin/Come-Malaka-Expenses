class EventsController < ApplicationController

	before_action :authenticate_user!

  ensure_authorization_performed

  authorize_actions_for Event


  def index
    @events = Event.with_role(:event_participant, current_user)
  end


  def new																			
  	@event = Event.new(from_date: Date.today, to_date: Date.today+3.days, organizer_id: current_user.id)
    authorize_action_for @event
  end


  def create
  	@event = Event.create(event_params)
    @event.add_participant current_user
    if @event.invalid? then
      flash[:notice] = "Event is invalid. Please correct."
      render :new and return
    end
    @event.save
  	flash[:notice] = "Event created."
  	redirect_to events_path
  end


  def edit
    @event = Event.find params[:id]
    authorize_action_for(@event)
  end


  def update
    @event = Event.find params[:id]
    @event.update_attributes event_params if authorize_action_for(@event)
    if @event.invalid? then
      flash[:notice] = "Event cannot be updated with invalid data. Please correct."
      render :edit and return
    end
    flash[:notice] = "Event updated."
    redirect_to events_path
  end


  def destroy
    event = Event.find(params[:id])
    if event.items.count == 0  then
      event.destroy if authorize_action_for(event)
      flash[:notice] = "Event deleted."
    else
      flash[:notice] = "Event cannot be deleted. Posted items exist."
    end
	  redirect_to events_path
  end


  def show
    @event = Event.find params[:id]
    authorize_action_for(@event)
  end


  def event_all_items
    event = Event.find(params[:event_id])
    authorize_action_for(event)
    @items = event.items
  end


  def expense_report
    @event = Event.find(params[:event_id])
    authorize_action_for(@event)
    @participants = @event.users
    @items = @event.items
  end


  private

  def event_params
  	params.require(:event).permit(:name, :from_date, :to_date, :description, :organizer_id, :event_currency, :user_ids => [], :users => [])
  end

end
