class ItemsController < ApplicationController

	before_action :authenticate_user!

  ensure_authorization_performed

  authorize_actions_for Item

  def index
    event = Event.find params[:event_id]
    authorize_action_for event
  	@items = event.items.in(payer_id: current_user.id)
  end

  def new
    @event = Event.find params[:event_id]
    authorize_action_for @event
    @item = @event.items.build(payer_id: current_user.id, value_date: @event.from_date)
  end

  #candidate for refactoring: put logic into Item model
  def create
    @item = Item.new(item_params)
    @item.event_id = params[:event_id]
    authorize_action_for @item.event
    if @item.exchange_rate.blank? or @item.exchange_rate.to_d.zero? then
      get_exchange_rate_for @item
      @item.valid?
      render :new and return
    end
    @item.base_amount = @item.foreign_amount * @item.exchange_rate
    if @item.invalid? then (render :new and return) end
    @item.save
    @item.initialize_roles
    redirect_to(event_items_path, :notice => "Item created")
  end

  def edit
    @item = Item.find params[:id]
    authorize_action_for @item
    @event = @item.event
  end

  #candidate for refactoring: put logic into Item model
  def update
    @item = Item.find params[:id]
    @item.update_attributes item_params
    if @item.exchange_rate.to_d.zero? then
      get_exchange_rate_for @item
      @item.valid?
      render :edit and return
    end
    @item.base_amount = @item.foreign_amount * @item.exchange_rate
    if @item.invalid? then (render :edit and return) end
    @item.save if authorize_action_for @item
    redirect_to event_items_path(event_id: @item.event), :notice => "Item updated"
  end

  def destroy
    item = Item.find(params[:id])
    event = item.event
    item.destroy if authorize_action_for item
    redirect_to event_items_path(event_id: event), :notice => "Item deleted"
  end

  def show
    @item = Item.find params[:id]
    authorize_action_for @item
  end

  private

  def item_params
    params.require(:item).permit(:name, :value_date, :description, :payer_id, :exchange_rate, :base_amount, :base_currency, :foreign_amount, :foreign_currency, :event, :beneficiary_ids => [])
  end

  def get_exchange_rate_for item
    item.apply_exchange_rate
    @item = item
    flash[:notice] = "Currency exchange updated..."
  end

end
