require 'test_helper'

class EventInvitationsControllerTest < ActionController::TestCase

  #Test data initialized in test_helper.rb#setup
  #and truncated while teardown

  def setup
    super
    @request.env["devise.mapping"] = Devise.mappings[:user]
    sign_in @organizer
  end

  def teardown
    super
    sign_out @organizer
  end

  test "view new invite page" do
    get :new, event_id: @event.id
    assert_response :success
    assert_template :new
  end

  test "create an invitation for a new user" do
    assert_difference 'ActionMailer::Base.deliveries.size', +1 do
      post :create, event_id: @event.id, user: {email: "new_user@event.com", first_name: "New", last_name: "User", event_id: @event.id}
    end    
    assert_response :redirect
    assert_redirected_to events_path
    invite_email = ActionMailer::Base.deliveries.last 
    assert_equal "Packoooook - You have been invited to Come Malaka", invite_email.subject
    assert_equal 'new_user@event.com', invite_email.to[0]
    assert_match(/Packoooook new_user@event.com/, invite_email.body.to_s)
  end

  test "create an invitation for an existing non participant" do
    assert_no_difference 'ActionMailer::Base.deliveries.size' do
      post :create, event_id: @event.id, user: { email: "user6@event.com", event_id: @event.id }
    end
    assert_response :redirect
    assert_redirected_to events_path
    assert_equal "Javier Ductor had been added to the event.", flash[:notice]
    assert_includes assigns(:event).users, assigns(:invitee)
    assert assigns(:invitee).has_role?(:event_participant, assigns(:event))
    assigns(:event).items.each do |item|
      assigns(:invitee).has_role?(:event_participant, item)
    end
  end

  test "create an invitation for an existing/pending participant" do
    assert_no_difference 'ActionMailer::Base.deliveries.size' do
      post :create, event_id: @event.id, user: { email: "user5@event.com", event_id: @event.id }
    end
    assert_response :redirect
    assert_redirected_to events_path
    assert_equal "Neal Mundy is already participant of event or pending invitation acceptance.", flash[:notice]
  end

end
