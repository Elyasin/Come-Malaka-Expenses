class ItemAuthorizer < ApplicationAuthorizer

  # event participant can view
  def readable_by?(user, event)
    user.has_role?(:event_participant, event)
  end

  # event participant can create
  def creatable_by?(user, event)
    user.has_role?(:event_participant, event)
  end

  # item owner can update
  def updatable_by?(user)
    user.has_role?(:event_participant, resource) && resource.payer_id == user.id
  end

  # item owner can delete
  def deletable_by?(user)
    user.has_role?(:event_participant, resource) && resource.payer_id == user.id
  end

end