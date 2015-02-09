class Item
	include Mongoid::Document
  include Authority::Abilities
  resourcify

  #uses ItemAuthorizer by default

  require 'open-uri'

	field :name, type: String
	field :value_date, type: Date
	field :description, type: String
	belongs_to :event
  field :base_amount, type: BigDecimal
  field :base_currency, type: String
  field :exchange_rate, type: BigDecimal
  field :foreign_amount, type: BigDecimal
  field :foreign_currency, type: String
  field :payer_id, type: BSON::ObjectId
  has_and_belongs_to_many :beneficiaries, class_name: "User", inverse_of: nil

  validates :name, :description, :value_date, :event, :base_amount, :base_currency, :exchange_rate, 
    :foreign_amount, :foreign_currency, :payer_id, :beneficiaries, presence: true
  validates :base_amount, :foreign_amount, :exchange_rate, numericality: {greater_than_or_equal_to: 0}


  def initialize_roles
    self.event.users.each do |participant|
      participant.add_role :event_participant, self
    end
  end

  def cost_per_beneficiary
    self.base_amount / self.beneficiaries.count
  end

  #rework the method to catch exceptions
  def apply_exchange_rate
    begin
      rate = JSON.parse(open("http://devel.farebookings.com/api/curconversor/" + self.foreign_currency + "/" + self.base_currency + "/1/json").read)
      self.exchange_rate = rate[self.base_currency]
      self.base_amount = self.foreign_amount * self.exchange_rate
    rescue
      self.errors[:exchange_rate] = " cannot get exchange rate. If problem persists choose a currency or try to type a rate manually."
    end
  end

end