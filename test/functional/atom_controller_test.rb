# (C) Copyright IBM Corp. 2010
require File.dirname(__FILE__) + '/../test_helper'
require 'atom_controller'

# Re-raise errors caught by the controller.
class AtomController; def rescue_action(e) raise e end; end

class AtomControllerTest < ActionController::TestCase

  def setup
    @controller = AtomController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @tessa = Person.find_by_name('Tessa Lau')
  end

  # Retrieve some feeds and make sure they work
  def test_personfeed
    tessaid = $profile.shortname_for_person(@tessa)
    get :person, {:id => tessaid}
    assert_response :success
    assert_tag :tag => 'title', :content => "Tessa Lau's CoScripts"
    assert_tag :tag => 'title', :content => "First Procedure",
      :parent => { :tag => "entry" }
    assert_tag :tag => 'title', :content => "Second Procedure, Editors' Pick",
      :parent => { :tag => "entry" }
  end

  def test_personfeed_limit
    tessaid = $profile.shortname_for_person(@tessa)
    get :person, {:id => tessaid, :limit => "1"}
    assert_response :success
    assert_no_tag :tag => 'title', :content => "First Procedure",
      :parent => { :tag => "entry" }
  end

  # Smoke test only ... waiting on better xpath queries for html
  def test_recentfeed
    get :scripts, :sort => 'modified'
    assert_response :success, @response.body
    assert_tag :tag => 'title', :content => "CoScripts sorted by modified"
  end

  def test_recentfeed_limit
    get :scripts, {:limit => 1, :sort => 'modified'}
    assert_response :success, @response.body
    assert_no_tag :tag => 'title', :content => "First Procedure",
      :parent => { :tag => "entry" }
  end

  def test_with_privacy
    get :scripts, {:limit => -1, :sort => 'modified'}
    assert_response :success, @response.body
    assert_no_tag :tag => 'title', :content => "A private procedure",
      :parent => { :tag => "entry" }
  end

  def test_nonexistent_person_feed
    number_users_before = Person.find(:all)
    get :person, {:id => "doesnotexist@us.ibm.com"}
    assert_response :success
    assert_nil Person.find_by_email("doesnotexist@us.ibm.com")
    assert_equal number_users_before,Person.find(:all)
  end
   def test_blacklist
      Blacklist.create(:ip_address=>@request.remote_addr)
      get :home
      assert_response 406,@response.body
      assert_tag :tag => "a", :content => $profile.site_email
   end
end
