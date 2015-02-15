class HomeRoutesTest < ActionController::TestCase

  test "must route to home index" do
    assert_routing '/', controller: "home", action: "index"
  end
 

end