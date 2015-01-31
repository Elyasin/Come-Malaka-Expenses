class EventAuthorizer < ApplicationAuthorizer


  #only event participant can update Event
  def self.updatable_by?(user)
    user.has_role? :event_participant, Event
  end

  #only event participant can delete Event
  def self.deletable_by?(user)
    user.has_role? :event_participant, Event
  end

  #only event participant can read Event
  def self.readable_by?(user)
  	user.has_role? :event_participant, Event
  end


  #only event participant can create item => used for Item
  #deactivated in Event
  def creatable_by?(user)
  	user.has_role? :event_participant, resource
  end

  #only event organizer can update event
  def updatable_by?(user)
    user.has_role?(:event_participant, resource) && resource.organizer_id == user.id
  end

  #only event organizer can delete event
  def deletable_by?(user)
    user.has_role?(:event_participant, resource) && resource.organizer_id == user.id
  end

  #only event participant can view event
  def readable_by?(user)
  	user.has_role? :event_participant, resource
  end


end