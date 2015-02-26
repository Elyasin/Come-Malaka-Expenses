require 'test_helper'

class EventInvitationsControllerTest < ActionController::TestCase
    include Rails.application.routes.url_helpers

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
    assert_response :success, "Response must be success"
    assert_template :new, "New page must be rendered"
  end

  test "create an invitation for a new user" do
    assert_difference('ActionMailer::Base.deliveries.size', +1, message = "An invitation email must be created") do
      post :create, event_id: @event.id, user: {email: "new_user@event.com", first_name: "New", last_name: "User", event_id: @event.id}
    end    
    assert_response :redirect, "Response must be redirect"
    assert_redirected_to events_path, "Redirect must be events_path"
    invite_email = ActionMailer::Base.deliveries.last 
    assert_equal "Packoooook - You have been invited to Come Malaka", invite_email.subject, "Email subject incorrect"
    assert_equal 'new_user@event.com', invite_email.to[0], "Invitee email is incorrect"
    assert_match /Packoooook New User/, invite_email.text_part.body.to_s, "Greeting in invitation email is incorrect"
    assert_match /You have been invited to join a Come Malaka event at #{root_url(host: "localhost:3000")}, you can accept it through the link below./, invite_email.text_part.body.to_s, "Invitation intro sentence is incorrect"
    assert_match /Accept invitation: #{accept_user_invitation_url(host: "localhost:3000")}/, invite_email.text_part.body.to_s, "Accept invitation link is incorrect"
    assert_match /If you don't want to accept the invitation, please ignore this email.\nYour account won't be created until you access the link above and set your password./, invite_email.text_part.body.to_s, "Invitation ignore sentence is incorrect"
  end

  test "create an invitation for an existing non participant" do
    assert_difference('ActionMailer::Base.deliveries.size', 1, message = "An invitation email must be created for existing user") do
      post :create, event_id: @event.id, user: { email: "user6@event.com", event_id: @event.id }
    end
    assert_response :redirect, "Response must be redirect"
    assert_redirected_to events_path, "Redirect must be events_path"
    assert_equal "#{assigns(:invitee).name} had been added to the event.", flash[:notice], "Flash[:notice] must state that user has been added to event"
    assert_includes assigns(:event).users, assigns(:invitee), "New participant must be participant of event"
    assert assigns(:invitee).has_role?(:event_participant, assigns(:event)), "New participant must have event participant role for event"
    assigns(:event).items.each do |item|
      assert assigns(:invitee).has_role?(:event_participant, item), "New participant must have event participant role for event's items"
    end
    invite_email = ActionMailer::Base.deliveries.last
    assert_equal "You have been invited to event " + assigns(:event).name, invite_email.subject, "Email subject incorrect"
    assert_equal "#{assigns(:invitee).email}", invite_email.to[0], "Invitee email is incorrect"
    assert_match /^Packooook #{assigns(:invitee).name}/, invite_email.text_part.body.to_s, "Greeting in invitation email is incorrect"  
    assert_match /You have been invited to the Come Malaka event #{assigns(:event).name}/, invite_email.text_part.body.to_s, "Email body is incorrect"
    assert_match /You can access the event with this link: #{event_url(assigns(:event), host: "localhost:3000")}/, invite_email.text_part.body.to_s, "Email body is incorrect"
  end

  test "create an invitation for an existing/pending participant" do
    assert_no_difference('ActionMailer::Base.deliveries.size', message = "No invitation must be created for existing participant or pending invitation") do
      post :create, event_id: @event.id, user: { email: "user5@event.com", event_id: @event.id }
    end
    assert_response :redirect, "Response must be redirect"
    assert_redirected_to events_path, "Redirect must be events_path"
    assert_equal "Neal Mundy is already participant of event or pending invitation acceptance.", flash[:notice], "flash[:notice] must state that user is already participant or pending invitation"
  end

end
