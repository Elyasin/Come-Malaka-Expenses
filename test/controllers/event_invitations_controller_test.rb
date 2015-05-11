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

  test "view new invitation page" do
    get :new, event_id: @event.id
    assert_response :success, "Response must be success"
    assert_template :new, "New page must be rendered"

    # Test the view
    assert_select 'title', "Invite to Randers event"

    # Test off-canvas menu
    assert_select ".left-off-canvas-menu ul li a[href=?]", event_all_items_path(assigns(:event)), "Back to all items"
    assert_select ".left-off-canvas-menu ul li a[href=?]", event_items_path(assigns(:event)), "Back to your items"
    assert_select ".left-off-canvas-menu ul li a[href=?]", events_path, "Back to events"
    assert_select ".left-off-canvas-menu ul li.has-submenu a[href='#']", "Randers event"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.back a[href='#']", "Back"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li a[href=?]", new_event_path, "Create new event"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li label", "Randers event"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li a[href=?]", invite_to_event_path(assigns(:event)), "Invite to event"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li a[href=?]", event_path(assigns(:event)), "View event details"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li a[href=?]", edit_event_path(assigns(:event)), "Edit event"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li a[href=?][data-method=delete]", event_path(assigns(:event)), "Delete event"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.has-submenu a[href='#']", "Expense Reports"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.has-submenu li.back a[href='#']", "Back"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.has-submenu li label", "Expense Reports"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.has-submenu li a[href=?]", expense_report_path(assigns(:event)), "Expense summary"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.has-submenu li a[href=?]", who_owes_you_path(assigns(:event)), "Who owes you?"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.has-submenu li a[href=?]", you_owe_whom_path(assigns(:event)), "You owe whom?"
    assert_select ".left-off-canvas-menu ul li.has-submenu a[href='#']", "Randers event"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li.back a[href='#']", "Back"
    assert_select ".left-off-canvas-menu ul li.has-submenu ul.left-submenu li a[href=?]", new_event_item_path(assigns(:event)), "Create new item"

    # Test top-bar menu
    assert_select ".title-area li.name  h1  a[href='#']", "Come Malaka!"
    assert_select ".top-bar-section li a[href=?]", new_event_path, "Create new event"
    assert_select ".top-bar-section li.has-dropdown a[href='#']", "Back to ..."
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?]", events_path, "... events"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?]", event_all_items_path(assigns(:event)), "... all items (#{assigns(:event).name})"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?]", event_items_path(assigns(:event)), "... your items (#{assigns(:event).name})"
    assert_select ".top-bar-section li.has-dropdown a[href='#']", "Randers event"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li.active a[href=?]", invite_to_event_path(assigns(:event)), "Invite to event"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?]", event_path(assigns(:event)), "View event details"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?]", edit_event_path(assigns(:event)), "Edit event"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?][data-method=delete]", event_path(assigns(:event)), "Delete event"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li.has-dropdown a[href='#']", "Expense Reports"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li.has-dropdown ul.dropdown a[href=?]", expense_report_path(assigns(:event)), "Expense summary"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li.has-dropdown ul.dropdown li a[href=?]", who_owes_you_path(assigns(:event)), "Who owes you?"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li.has-dropdown ul.dropdown li a[href=?]", you_owe_whom_path(assigns(:event)), "You owe whom?"
    assert_select ".top-bar-section li.has-dropdown a[href='#']", "Randers items"
    assert_select ".top-bar-section li.has-dropdown ul.dropdown li a[href=?]", new_event_item_path(assigns(:event)), "Create new item"

    # Test form and Foundation (Abide, Grid)
    assert_select "form[data-abide=true]"
    assert_select "form[novalidate=novalidate]"
    assert_select "form input#user_event_id[value=?]", @event.id.to_s
    assert_select "form div.row div.small-12.medium-8.large-6.columns.small-centered fieldset" do
      assert_select "legend", "Invite to #{@event.name} event"
      assert_select "div.row", 4
      assert_select "div.row div.field.small-12.medium-4.large-4.columns.end label", "Email"
      assert_select "div.row div.small-12.medium-8.large-8.columns.end input#user_email[required=required]" 
      assert_select "div.row div.small-12.medium-8.large-8.columns.end input[pattern=email]" 
      assert_select "div.row div.small-12.medium-8.large-8.columns.end input[placeholder=?]", "Email"
      assert_select "div.row div.small-12.medium-8.large-8.columns.end small.error", "Email is required. Make sure you type in a valid email."
      assert_select "div.row div.field.small-12.medium-4.large-4.columns.end label", "First name"
      assert_select "div.row div.small-12.medium-8.large-8.columns.end input#user_first_name[placeholder=?]", "Leave blank if not known"
      assert_select "div.row div.field.small-12.medium-4.large-4.columns.end label", "Last name"
      assert_select "div.row div.small-12.medium-8.large-8.columns.end input#user_last_name[placeholder=?]", "Leave blank if not known"
      assert_select "div.row div.actions.small-12.medium-8.large-8.columns.end input[value=?]", "Send an invitation"
    end
  end

  test "view accept invitation page" do
    sign_out @organizer
    new_participant = User.invite!(:email => "new_participant@event.com", event_id: @event.id) do |u|
      u.skip_invitation = true
    end
    get :edit, invitation_token: new_participant.raw_invitation_token
    assert_response :success, "Response must be success"
    assert_template :edit, "Edit page must be rendered"
    # Test the view
    assert_select 'title', "Accept invitation to Randers event"
    # Test form and Foundation (Abide and Grid)
    assert_select "form[data-abide=?]", "true"
    assert_select "form[novalidate=?]", "novalidate"
    assert_select "form input#user_invitation_token[value=?]", new_participant.raw_invitation_token
    assert_select "form div.row div.small-12.medium-8.large-6.columns.small-centered fieldset" do
      assert_select "legend", "Set your password"
      assert_select "div.row", 3
      assert_select "div.row div.field.password-field.small-12.medium-4.large-4.columns.end label", "Password"
      assert_select "div.row div.password-field.small-12.medium-8.large-8.columns.end input#user_password[required=?]", "required"
      assert_select "div.row div.password-field.small-12.medium-8.large-8.columns.end small.error", "Password length must be at least 8 characters."
      assert_select "div.row div.field.password-confirmation-field.small-12.medium-4.large-4.columns.end label", "Password confirmation"
      assert_select "div.row div.password-confirmation-field.small-12.medium-8.large-8.columns.end input#user_password_confirmation[required=?]", "required"
      assert_select "div.row div.password-confirmation-field.small-12.medium-8.large-8.columns.end input#user_password_confirmation[data-equalto=?]", "user_password"
      assert_select "div.row div.password-confirmation-field.small-12.medium-8.large-8.columns.end small.error", "Password did not match."
      assert_select "div.row div.actions.small-12.medium-8.large-8.columns.end input[value=?]", "Set my password"
    end
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
