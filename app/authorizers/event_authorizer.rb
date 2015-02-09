class EventAuthorizer < ApplicationAuthorizer
  
  # event participant can create
  def creatable_by?(user)
    user.has_role? :event_user
  end

  # event organizer can update
  def updatable_by?(user)
    user.has_role?(:event_participant, resource) and resource.organizer_id == user.id
  end

  # event organizer can delete
  def deletable_by?(user)
    user.has_role?(:event_participant, resource) and resource.organizer_id == user.id# and resource.items.empty? and resource.users.empty?
  end

end