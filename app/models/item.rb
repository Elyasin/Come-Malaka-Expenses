class Item
	include Mongoid::Document
	include Mongoid::MoneyField

	field :name, type: String
	field :value_date, type: Date
	field :description, type: String
	belongs_to :event
  money_field :base_amount, default: 0, required: true
  field :exchange_rate, type: BigDecimal
  money_field :foreign_amount, default: 0, required: true
  field :payer_id, type: BSON::ObjectId
  has_and_belongs_to_many :beneficiaries, class_name: "User", inverse_of: nil


  # returns a big decimal for better accuracy
  def cost_per_beneficiary
    self.base_amount / self.beneficiaries.count
  end

  # returns Money object with base currency
  def cost_per_beneficiary_amount
    self.base_amount.amount / self.beneficiaries.count
  end

end