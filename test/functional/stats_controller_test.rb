# (C) Copyright IBM Corp. 2010
require File.dirname(__FILE__) + '/../test_helper'
require 'stats_controller'

# Re-raise errors caught by the controller.
class StatsController; def rescue_action(e) raise e end; end

class StatsControllerTest < ActionController::TestCase
  def setup
    @controller = StatsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_per_day
    get :users_by_day
    assert_response :success

    get :pageviews_by_day
    assert_response :success
  end
   def test_blacklist
      Blacklist.create(:ip_address=>@request.remote_addr)
      get :home
      assert_response 406,@response.body
      assert_tag :tag => "a", :content => $profile.site_email
   end
end
