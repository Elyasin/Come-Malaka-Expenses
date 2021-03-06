require 'test_helper'

class ApplicationControllerTest < ActionController::TestCase

  # testing the hook methods directly
  # Is there a better/simpler way?

  def setup
    super

    def @controller.after_sign_in_path_for(resource_or_scope)
      super resource_or_scope
    end

    def @controller.after_sign_out_path_for(resource_or_scope)
      super resource_or_scope
    end

    def @controller.after_sign_up_path_for(resource_or_scope)
      super resource_or_scope
    end

  end

  test "after sign in path" do
  	assert_equal events_path, @controller.after_sign_in_path_for(@organizer), "After sign up path must be events_path"
  end

  test "after sign out path" do
    assert_equal root_path, @controller.after_sign_out_path_for(@organizer), "After sign up path must be roo_path"
  end

  test "after sign up path" do
    assert_equal events_path, @controller.after_sign_up_path_for(@organizer), "After sign up path must be events_path"
  end

end
