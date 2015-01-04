class ItemsController < ApplicationController

	before_action :authenticate_user!

  def index
    event = Event.find params[:event_id]
  	@items = event.items.in(payer_id: current_user.id)
  end

  def new
    @event = Event.find params[:event_id]
    @item = @event.items.build(payer_id: current_user.id, value_date: @event.from_date)
  end

  def create
    item = Item.new(item_params)
    item.event_id = params[:event_id]
    foreign_currency = Money::Currency.new params[:foreign_currency]
    base_currency = Money::Currency.new params[:base_currency]
    Money.add_rate(foreign_currency, base_currency, params[:item][:exchange_rate].to_d)
    item.foreign_amount = Money.new((params[:foreign_amount].to_d * foreign_currency.subunit_to_unit), foreign_currency)   
    item.base_amount = Money.new(item.foreign_amount.exchange_to(base_currency), base_currency)
    item.save
    redirect_to(event_items_path, :notice => "Item created") and return
  end

  def edit
    @item = Item.find params[:id]
  end

  def update
    item = Item.find params[:id]
    item.update_attributes item_params
    foreign_currency = Money::Currency.new params[:foreign_currency]
    base_currency = Money::Currency.new params[:base_currency]
    Money.add_rate(foreign_currency, base_currency, params[:item][:exchange_rate].to_d)
    item.foreign_amount = Money.new((params[:foreign_amount].to_d * foreign_currency.subunit_to_unit), foreign_currency)   
    item.base_amount = Money.new(item.foreign_amount.exchange_to(base_currency), base_currency)
    item.save
    redirect_to event_items_path(event_id: item.event), :notice => "Item updated"
  end

  def destroy
    item = Item.find(params[:id])
    event = item.event
    item.destroy
    redirect_to event_items_path(event_id: event), :notice => "Item deleted"
  end

  def show
    @item = Item.find params[:id]
  end

  def item_params
    params.require(:item).permit(:name, :value_date, :description, :payer_id, :exchange_rate, :beneficiary_ids => [])
  end

end
