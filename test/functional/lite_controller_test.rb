# (C) Copyright IBM Corp. 2010
require File.dirname(__FILE__) + '/../test_helper'
require 'lite_controller'

# Re-raise errors caught by the controller.
class LiteController; def rescue_action(e) raise e end; end

class LiteControllerTest < ActionController::TestCase
  def setup
    @controller = LiteController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

	@tessa = Person.find(1)
  end

  # Replace this with your real tests.
  def test_metatags
    @request.session[:user_id] = 1
    get :script, {:id => 1}
    assert_tag :tag => "meta", :attributes => { :name => "coscripter-script-id" }
    assert_tag :tag => "meta", :attributes => { :name => "coscripter-script-url" }
    assert_tag :tag => "meta", :attributes =>
      { :name => "coscripter-script-lite-url" }
    
    @request.session[:user_id] = 1
    get :edit, {:id => 1}
    assert_tag :tag => "meta", :attributes => { :name => "coscripter-script-id" }
    assert_tag :tag => 'meta', :attributes => { :name => 'coscripter-save-url' }
    assert_tag :tag => 'meta', :attributes => { :name => 'coscripter-author-email' }
  end

  def test_private_script_unauthorized
    get :script, {:id => 7}
    assert_response 302, @response.body
  end

  def test_private_script_notmine
    @request.session[:user_id] = 3
    get :script, {:id => 7}
    assert_response 404, @response.body
    assert_equal "This script does not exist or has been deleted.",
      @response.body
  end

  def test_login_firstime_user_registration_required
    $profile = TestProfile.new
    $profile.needs_registration = true
    assert_nil Person.find_by_email('success')
    post :login,{:redirect => '/',:user =>{ 'w3login' => 'success' , 'w3pass' => 'success' } }
    assert_response :success
    assert_nil session[:user_id]
  end

  def test_login_firstime_user
    number_people_before = Person.find(:all).length
    $profile = TestProfile.new
    $profile.needs_registration = false 
    post :login,{:redirect => '/',:user =>{ 'w3login' => 'success' , 'w3pass' => 'success' } }

    assert_response :redirect
    assert_redirected_to '/'
    assert_equal number_people_before + 1,Person.find(:all).length
    assert_equal session[:user_id],Person.find_by_email('success').id
    Person.find_by_email('success').destroy
  end

  def test_makewish
    @request.session[:user_id] = @tessa.id
	get :make_wish, {:url => "http://google.com", :title => "Google"}
	assert_response :success, @response.body
	wish1 = Wish.find(1)
	wish2 = Wish.find(2)
	assert_tag :tag => "a", :content => wish2.wish
	assert_no_tag :tag => "a", :content => wish1.wish
  end

  def test_find_related
    @request.session[:user_id] = @tessa.id
	get :find_related, {:url => "http://google.com", :title => "Google"}
	assert_response :success, @response.body
	wish1 = Wish.find(1)
	wish2 = Wish.find(2)
	assert_tag :tag => "a", :content => wish2.wish
	assert_no_tag :tag => "a", :content => wish1.wish
	assert_tag :tag => "a", :content => wish2.person.name
  end
   def test_blacklist
      Blacklist.create(:ip_address=>@request.remote_addr)
      get :home
      assert_response 406,@response.body
      assert_tag :tag => "a", :content => $profile.site_email
   end
end
