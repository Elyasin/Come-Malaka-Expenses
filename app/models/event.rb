class Event
  include Mongoid::Document
  include Authority::Abilities
  resourcify

  #uses EventAuthorzier by default

  field :name, type: String
  field :from_date, type: Date
  field :end_date, type: Date
  field :description, type: String
  field :event_currency, type: String
  has_and_belongs_to_many :users, inverse_of: nil
  has_many :items
  belongs_to :organizer, class_name: "User"

  validates :name, :description, :event_currency, :organizer, presence: true
  validate :event_currency_not_modified, on: :update
  validate :event_dates


  def event_dates
    self.errors[:from_date] = " must not be blank" if self.from_date.blank?
    self.errors[:end_date] = " must not be blank" if self.end_date.blank?
    if !(self.from_date.blank? or self.end_date.blank?) then
      self.errors[:base] = "'From date' must be before 'To Date'" unless (self.from_date <= self.end_date)
    end
  end

  def event_currency_not_modified
    self.errors[:event_currency] = " cannot be modified. Event contains items." if (!self.items.empty? and self.event_currency_changed?)
  end

  # returns false if user already participant
  # otherwise returns true
  def add_participant(user)
    return false if self.users.include?(user)
    user.add_role(:event_participant, self) unless user.has_role?(:event_participant, self)
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

  # who owes participant which items/amounts in this event
  def who_owes(participant, total_amount = Hash.new { |h,k| h[k] = 0 }, item_list = Hash.new { |h,k| h[k] = [] })
    self.items.where(payer_id: participant.id).order_by(value_date: :desc, name: :asc).each do |item|
      item.beneficiaries.each do |beneficiary|
        next unless beneficiary != participant
        total_amount[beneficiary] += item.cost_per_beneficiary
        item_list[beneficiary] << item
      end
    end
  end

  #participants owe whom which item/amount in this event
  def who_paid_for(beneficiary, total_amount = Hash.new { |h,k| h[k] = 0 }, item_list = Hash.new { |h,k| h[k] = [] })
    self.items.in(beneficiary_ids: beneficiary.id).order_by(value_date: :desc, name: :asc).each do |item|
      next unless beneficiary != item.payer
      total_amount[item.payer] += item.cost_per_beneficiary
      item_list[item.payer] << item
    end
  end

end
