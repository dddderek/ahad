require 'test_helper'

class PropertiesControllerTest < ActionDispatch::IntegrationTest

  test "should get existing property" do
    get "/properties/16494"
    assert_response :success
  end
end