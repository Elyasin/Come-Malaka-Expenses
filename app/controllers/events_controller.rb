class EventsController < ApplicationController

	before_action :authenticate_user!

  def index
  	@events = Event.in(user_ids: current_user.id)
  end

  def new																			
  	@event = Event.new(from_date: Date.today, to_date: Date.today+3.days, organizer_id: current_user.id)
  end

  def create
  	event = Event.create(event_params)
    event.add_participant current_user
    event.save
  	flash[:notice] = "Event created"
  	redirect_to events_path
  end

  def edit
    @event = Event.find params[:id]
  end

  def update
    event = Event.find params[:id]
    event.update_attributes event_params
    redirect_to event_path(event.id)
  end

  def destroy
    Event.find(params[:id]).destroy
  	flash[:notice] = "Event deleted"
	  redirect_to events_path
  end

  def show
    @event = Event.find params[:id]
  end

  def items_index
    @items = Event.find(params[:event_id]).items
  end

  def expense_report
    @event = Event.find(params[:event_id])
    @participants = @event.users
    @items = @event.items
  end

  private

  def event_params
  	params.require(:event).permit(:name, :from_date, :to_date, :description, :organizer_id, :event_currency, :user_ids => [], :users => [])
  end

end
