class ItemAuthorizer < ApplicationAuthorizer


  #only event participant can create an Item
  def self.creatable_by?(user)
    user.has_role? :event_participant, Event
  end

  #only event participant can update Item
  def self.updatable_by?(user)
    user.has_role? :event_participant, Event
  end

  #only event participant can delete Item
  def self.deletable_by?(user)
    user.has_role? :event_participant, Event
  end

  #only event participant can read Item
  def self.readable_by?(user)
  	user.has_role? :event_participant, Event
  end


  #only item owner can update item
  def updatable_by?(user)
    user.has_role?(:item_owner, resource) && resource.payer_id == user.id
  end

  #only item owner can delete item
  def deletable_by?(user)
    user.has_role?(:item_owner, resource) && resource.payer_id == user.id
  end

  #only event participant can view item
  def readable_by?(user)
  	user.has_role? :event_participant, resource
  end


end