# Other authorizers should subclass this one
class ApplicationAuthorizer < Authority::Authorizer


  #event_user role can call any event or item action
  #
  #event_participant role is scoped to resource instances
  #
  #item_owner role is scoped to resource instances


  # Any class method from Authority::Authorizer that isn't overridden
  # will call its authorizer's default method.
  #
  # @param [Symbol] adjective; example: `:creatable`
  # @param [Object] user - whatever represents the current user in your app
  # @return [Boolean]
  def self.default(adjective, user)
    # Event participants are permitted to any adjective
    user.has_role? :event_user
  end
  
  # event participant can view
  def readable_by?(user)
    user.has_role? :event_participant, resource
  end

end
