class Event
  include Mongoid::Document
  include Authority::Abilities
  resourcify

  #uses EventAuthorzier by default

  field :name, type: String
  field :from_date, type: Date
  field :to_date, type: Date
  field :description, type: String
  field :event_currency, type: String
  has_and_belongs_to_many :users, inverse_of: nil
  has_many :items
  field :organizer_id, type: BSON::ObjectId

  validates :name, :from_date, :to_date, :description, :event_currency, :organizer_id, presence: true

  #add user to event if user not already participant
  #true		user successfully added
  #false	user already participant of event
  def add_participant(user)
    return false if self.users.include?(user)
    user.add_role :event_participant, self
    self.users << user
    self.items.each do |item| item.initialize_role_for user end
    true
  end

  # returns items that were paid by participant (base amount)
  def paid_expense_items_by participant
    self.items.where(payer_id: participant.id)
  end
  
  # returns the total amount of items paid by participant (base amount)
  def total_expenses_amount_for participant
    total = 0.to_d
    self.paid_expense_items_by(participant).each do |item|
      total = total + item.base_amount
    end
    total
  end

  # returns the total amount of items of which participant is a beneficiary (base amount)
  def total_benefited_amount_for participant
    benefited_amount = 0.to_d
    self.items.each do |item|
      if item.beneficiaries.include? participant then
        benefited_amount = benefited_amount + item.cost_per_beneficiary
      end
    end
    benefited_amount
  end

  # balance = total amount paid by participant - total amount benefited by participant
  def balance_for participant
    total_expenses_amount_for(participant) - total_benefited_amount_for(participant)
  end

  #returns the organizer's name
  def organizer
    User.find(self.organizer_id).name
  end

end
