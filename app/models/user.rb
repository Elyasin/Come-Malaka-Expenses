class User
  include Mongoid::Document
  include Authority::UserAbilities
  rolify

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :invitable, :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable#, :confirmable

  acts_as_token_authenticatable
  field :authentication_token

  ## First and last name
  field :first_name,         type: String, default: ""
  field :last_name,          type: String, default: ""

  ## Database authenticatable
  field :email,              type: String, default: ""
  field :encrypted_password, type: String, default: ""

  ## Recoverable
  field :reset_password_token,   type: String
  field :reset_password_sent_at, type: Time

  ## Rememberable
  field :remember_created_at, type: Time

  ## Trackable
  field :sign_in_count,      type: Integer, default: 0
  field :current_sign_in_at, type: Time
  field :last_sign_in_at,    type: Time
  field :current_sign_in_ip, type: String
  field :last_sign_in_ip,    type: String

  ## Confirmable
  # field :confirmation_token,   type: String
  # field :confirmed_at,         type: Time
  # field :confirmation_sent_at, type: Time
  # field :unconfirmed_email,    type: String # Only if using reconfirmable

  ## Lockable
  # field :failed_attempts, type: Integer, default: 0 # Only if lock strategy is :failed_attempts
  # field :unlock_token,    type: String # Only if unlock strategy is :email or :both
  # field :locked_at,       type: Time

  field :invitation_token, type: String
  field :invitation_created_at, type: Time
  field :invitation_sent_at, type: Time
  field :invitation_accepted_at, type: Time
  field :invitation_limit, type: Integer
  #Event ID for invitation
  #field :event_id, type: BSON::ObjectId
  belongs_to :event, optional: true
  #delete_at field for soft delete
  field :deleted_at, type: Date
 
  index( {invitation_token: 1}, {:background => true} )
  index( {invitation_by_id: 1}, {:background => true} )


  # instead of deleting, indicate the user requested a delete & timestamp it  
  def soft_delete  
    update_attribute(:deleted_at, Time.current)  
  end  

  # ensure user account is active  
  def active_for_authentication?  
    super && !deleted_at  
  end  

  # provide a custom message for a deleted account   
  def inactive_message   
    !deleted_at ? super : :deleted_account  
  end 


  def short_name
    self.first_name.blank? ? self.email : self.first_name
  end

  def name
    self.first_name.blank? ? self.email : self.first_name + " " + self.last_name
  end

  def email_addressing
    if self.first_name.blank? and self.last_name.blank? then
      self.email
    else
      %("#{self.name}" <#{self.email}>)
    end
  end

  #Add the user to the event after accepting invitation
  after_invitation_accepted :add_to_invited_event

  def add_to_invited_event
    self.event.add_participant(self) if !event.nil?
    self.event = nil
  end

  #Assign default role to user
  after_create :assign_default_role

  def assign_default_role
    self.add_role(:event_user) unless self.has_role?(:event_user)
  end

  after_destroy :revoke_default_role

  def revoke_default_role
    self.revoke :event_user
  end

  # Alias to avoid Method not found error due to upgrade
  alias will_save_change_to_email? email_changed?

end
