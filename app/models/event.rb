class Event
  include Mongoid::Document

  field :name, type: String
  field :from_date, type: Date
  field :to_date, type: Date
  field :description, type: String
  field :event_currency, type: String, default: "EUR"
  has_and_belongs_to_many :users, inverse_of: nil
  has_many :items
  field :organizer_id, type: BSON::ObjectId

  #add user to event if user not already participant or not yet invited
  #true		user successfully added
  #false	user already participant of or invited to event
  def add_participant(user)
  	if not users.include? user then
	  	self.users << user
  	end
  end

  # returns items that were paid by participant
  def paid_expense_items_by participant
    self.items.where(payer_id: participant.id)
  end
  
  # returns the total amount of items paid by participant
  def total_expenses_amount_for participant
    total = Money.new 0, self.event_currency
    self.paid_expense_items_by(participant).each do |item|
      total = total + item.base_amount
    end
    total
  end

  # returns the total amount of items of which participant is a beneficiary
  def total_benefited_amount_for participant
    benefited_amount = 0.to_d
    self.items.each do |item|
      if item.beneficiaries.include? participant then
        benefited_amount = benefited_amount + item.cost_per_beneficiary_amount
      end
    end
    benefited_amount
    currency = Money::Currency.new self.event_currency
    Money.new benefited_amount * currency.subunit_to_unit, self.event_currency
  end

  # balance = total amount paid by participant - total amount benefited by participant
  def balance_for participant
    total_expenses_amount_for(participant) - total_benefited_amount_for(participant)
  end

  def organizer
    User.find(self.organizer_id).name
  end

end
