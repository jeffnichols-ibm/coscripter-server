# (C) Copyright IBM Corp. 2010
require File.dirname(__FILE__) + '/../test_helper'
require 'help_controller'

# Re-raise errors caught by the controller.
class HelpController; def rescue_action(e) raise e end; end

class HelpControllerTest < ActionController::TestCase
  def setup
    @controller = HelpController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
   def test_blacklist
      Blacklist.create(:ip_address=>@request.remote_addr)
      get :home
      assert_response 406,@response.body
      assert_tag :tag => "a", :content => $profile.site_email
   end
end
