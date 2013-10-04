# (C) Copyright IBM Corp. 2010
require File.dirname(__FILE__) + '/../test_helper'
require 'login_controller'
require 'test-profile'
require 'wi-profile'
require 'standalone-profile'

# Re-raise errors caught by the controller.
class LoginController; def rescue_action(e) raise e end; end

class LoginControllerTest < ActionController::TestCase

  def setup
    $profile = TestProfile.new
    @controller = LoginController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_authenticate_person
    assert $profile.authenticate_person('success','success')
    assert $profile.authenticate_person('success','any')==false
    assert $profile.authenticate_person('any','any')==false
  end

  def test_login_user_no_reg
    #firsttime user no registration needed
    number_users_before = Person.find(:all).length
    $profile.needs_registration = false 
    post :login,{ :user => { :w3login => 'success' , :w3pass =>'success'}, :redirect=>"http://www.ibm.com"}
    assert_response :redirect, @response.body
    assert_redirected_to "http://www.ibm.com"
    success = Person.find_by_email('success')
    assert_equal 'success',success.email
    assert_equal session[:user_id],success.id
    assert_equal number_users_before+1 , Person.find(:all).length
    success.destroy
  end

 def test_login_user
    # firsttime user registration required forwards to registration page 
    # without creating a new Person yet
    $profile.needs_registration = true
    assert_nil Person.find_by_id('success')
    post :login,{ :user => { :w3login => 'success' , :w3pass =>'success'}, :redirect=>"http://www.ibm.com"}
    assert_response :redirect, @response.body
    assert_redirected_to({ :controller => "login", :action => "register" , :redirect=>"http://www.ibm.com"})
    assert_nil Person.find_by_id('success')
    assert_equal "success",session[:registerid]
  end
  
  def test_login_user_relative_redirect
    redirect_url = 'http://' + $profile.hostname + '/test'
    $profile.needs_registration = true
    @request.host =  $profile.hostname 
    post :login,{ :user => { :w3login => 'jameslin@us.ibm.com' , :w3pass =>'jameslin@us.ibm.com'}, :redirect=>"/test"}
    assert_response :redirect, @response.body
    assert_redirected_to redirect_url
    assert_equal session[:user_id],Person.find_by_email('jameslin@us.ibm.com').id

    redirect_url = 'http://' + $profile.hostname + '/test'
    $profile.needs_registration = false
    @request.host =  $profile.hostname 
    post :login,{ :user => { :w3login => 'jameslin@us.ibm.com' , :w3pass =>'jameslin@us.ibm.com'}, :redirect=>"/test"}
    assert_response :redirect, @response.body
    assert_redirected_to redirect_url
    assert_equal session[:user_id],Person.find_by_email('jameslin@us.ibm.com').id
  end
  
  def test_register
    number_users_before = Person.find(:all).length

    $profile.needs_registration = true
    @request.session[:registerid] = 'success'
    do_ssl_request
    get(:register)
    assert_response :success    
    assert_equal number_users_before , Person.find(:all).length

    # try to register with no registerid set in the session => goes back to login
    $profile.needs_registration = true
    @request.session[:registerid] = nil
    do_ssl_request
    get(:register)
    assert_response :redirect
    assert_redirected_to :controller => "login", :action => "login"
    assert_equal number_users_before,Person.find(:all).length

    # try to register with no registerid set in the session => goes back to login
    @request.session[:registerid] = nil
    do_ssl_request
    post(:register,{ :user => { :displayname => Person.find(:first).name }, :redirect => "/"} )

    assert_response :redirect
    assert_redirected_to :controller => "login", :action => "login"
    assert_equal number_users_before,Person.find(:all).length

    # register firsttime user
    $profile.needs_registration = true
    @request.host = $profile.hostname
    number_users_before = Person.find(:all).length
    @request.session[:registerid] = 'success'
    do_ssl_request
    post(:register,{ :user => { :displayname => 'success' }, :redirect => "/"} )
    assert_response :redirect
    assert_redirected_to  'https://' + $profile.hostname + ":80/"
    success = Person.find_by_email('success')
    assert_equal 'success' ,success.email
    assert_equal success.id,session[:user_id]
	assert_equal true, success.accepted_alm_terms
    assert_equal number_users_before+1,Person.find(:all).length
    success.destroy
    assert_equal number_users_before,Person.find(:all).length

    @request.session[:registerid] = 'success'
    @request.session[:user_id] = nil
    do_ssl_request
    post(:register,{ :user => { :displayname => Person.find(:first).name }, :redirect => "/"} )
    assert_response :success
    assert_equal 'The name you have chosen is already taken. Please choose another one.', flash[:notice]
    assert_nil session[:user_id]
    assert_equal number_users_before,Person.find(:all).length

    @request.session[:registerid] = 'success'
    do_ssl_request
    post(:register,{ :user => { :displayname => "" }, :redirect => "/"} )
    assert_response :success
    assert_equal 'You need to choose a display name.', flash[:notice]
    assert_nil session[:user_id]
    assert_equal number_users_before,Person.find(:all).length

    @request.session[:registerid] = 'success'
    do_ssl_request
    post(:register,{ :user => { :displayname => "\#\@\$\%\%\^\&\*\!\@\:" }, :redirect => "/"} )
    assert_response :success
    assert_equal  'The name you have chosen contains characters that are not allowed.', flash[:notice]
    assert_nil session[:user_id]
    assert_equal number_users_before,Person.find(:all).length
  end

  def test_login_wrong_pw
    # wrong pw will always get you back to the login page with no user created
    # and no redirect
    $profile.needs_registration = true
    post :login,{ :user => { :w3login => 'success' , :w3pass =>'any'}, :redirect=>"http://www.ibm.com"}
    assert_response :success, @response.body
    assert_equal "Login failed. Please check your password and try again.", flash[:notice]
    assert_nil session[:user_id]
    # need to also assert that redirect parameter is a input type hidden in the response auth form

    $profile.needs_registration = false
    post :login,{ :user => { :w3login => 'success' , :w3pass =>'any'}, :redirect=>"http://www.ibm.com"}
    assert_response :success, @response.body
    assert_equal "Login failed. Please check your password and try again.", flash[:notice]
    assert_nil session[:user_id]
    # need to also assert that redirect parameter is a input type hidden in the response auth form
  end

  def test_wrong_pw2
    $profile.needs_registration = false
    post :login,{ :user => { :w3login => 'jameslin@us.ibm.com' , :w3pass =>'any'}, :redirect=>"http://www.ibm.com"}
    assert_response :success, @response.body
    assert_equal "Login failed. Please check your password and try again.", flash[:notice]
    assert_nil session[:user_id]
    # need to also assert that redirect parameter is a input type hidden in the response auth form

    $profile.needs_registration = true
    post :login,{ :user => { :w3login => 'jameslin@us.ibm.com' , :w3pass =>'any'}, :redirect=>"http://www.ibm.com"}
    assert_response :success, @response.body
    assert_equal "Login failed. Please check your password and try again.", flash[:notice]
    assert_nil session[:user_id]
  end

  def test_login_exists
    $profile.needs_registration = true
    post :login,{ :user => { :w3login => 'jameslin@us.ibm.com' , :w3pass =>'jameslin@us.ibm.com'}, :redirect=>"http://www.ibm.com"}
    assert_response :redirect, @response.body
    assert_redirected_to "http://www.ibm.com"
    assert_equal session[:user_id],Person.find_by_email('jameslin@us.ibm.com').id

    $profile.needs_registration = false
    post :login,{ :user => { :w3login => 'jameslin@us.ibm.com' , :w3pass =>'jameslin@us.ibm.com'}, :redirect=>"http://www.ibm.com"}
    assert_response :redirect, @response.body
    assert_redirected_to "http://www.ibm.com"
    assert_equal session[:user_id],Person.find_by_email('jameslin@us.ibm.com').id
  end

  def test_display_alm_terms
	# if you try to log in and you have not yet accepted the terms and
	# conditions, then you need to be redirected to the acceptance page ...
	# but only if needs_registration is true in the profile
	$profile.needs_registration = true
	post :login, {:user => { :w3login => "needsaccept@org", :w3pass => "passw0rd"}, :redirect => "http://REDIRECT_URL" }
	assert_response :redirect, @response.body
	assert_redirected_to :controller => "login", :action => "reaccept", :redirect=> "http://REDIRECT_URL"
	assert_equal session[:user_id], Person.find_by_email('needsaccept@org').id
  end

  def test_nodisplay_alm_terms
	# If you go to log in and you have not accepted the terms, but if this
	# profile does not require registration, then we don't have to display
	# the reacceptance page
	$profile.needs_registration = false
	post :login, {:user => { :w3login => "needsaccept@org", :w3pass => "passw0rd"}, :redirect => "http://REDIRECT_URL" }
	assert_response :redirect, @response.body
	assert_redirected_to "http://REDIRECT_URL"
	assert_equal session[:user_id], Person.find_by_email('needsaccept@org').id

	post :login, {:user => {:w3login => "jameslin@us.ibm.com", :w3pass => "jameslin@us.ibm.com"}, :redirect => "http://REDIRECT_URL"}
	assert_response :redirect, @response.body
	assert_redirected_to "http://REDIRECT_URL"
	assert_equal session[:user_id], Person.find_by_email("jameslin@us.ibm.com").id
  end

  def test_reaccept_get
	get :reaccept, {:redirect => "http://REDIRECT"}
	assert_response :success, @response.body
	assert_tag :content => /Please read the revised documents below/
  end

  def test_reaccept_post
	$profile.needs_registration = true
	p = Person.find_by_email('needsaccept@org')
	assert_equal false, p.accepted_alm_terms
    @request.session[:user_id] = p.id
	post :reaccept, {:terms_accepted => true, :redirect => "http://REDIRECT" }
	assert_response :redirect, @response.body
	assert_redirected_to "http://REDIRECT"
	assert_equal flash[:notice], "Thank you for accepting the updated terms and conditions"
	p.reload
	assert_equal true, p.accepted_alm_terms
  end

  def test_get_registerpage
    do_ssl_request
    get :register
    assert_response :redirect, @response.body
    assert_redirected_to({ :controller => "login", :action => "login" })
  end
 
  def test_post_registerpage
    $profile.needs_registration = false
    post :register, {:foo => :bar}
    assert_response :redirect, @response.body
    assert_redirected_to({ :controller => "login", :action => "login" })
    assert_nil session[:user_id]

    $profile.needs_registration = true
    post :register, {:foo => :bar}
    assert_response :redirect, @response.body   
    assert_redirected_to({ :controller => "login", :action => "login" })
    assert_nil session[:user_id]
  end

  def test_w3_cookie_not_ibm
	$profile = WiProfile.new

	@request.cookies = {}
	get :login
	assert :redirect, @response.body
  end

  def test_w3_cookie_yes_ibm
	$profile = WiProfile.new

	@request.cookies["w3ibmProfile"] = CGI::Cookie.new("w3ibmProfile", "test")
        #make sure we mock ssl so we won't get the redirect 
        @request.env['HTTPS'] = 'on'
	get :login
	assert_response :success, @response.body
	assert_tag "div", :attributes => { :class => "notice" },
		:content => /We think you might have access to the IBM intranet.*/
        assert_no_tag "div", :content => /Please log in with your IBM Intranet ID and password. /
  end
  
  def test_wi_with_sso
      $profile = WiProfile.new
      get :login
      assert_response :redirect, @response.body
  end

  def test_login_standalone
	$profile = StandaloneProfile.new
	post :login, {:user => {:w3login => "abc@def.ghi", :w3pass => "mypass"}, :redirect => "http://myredirect"}
	assert_response :redirect, @response.body
	assert_redirected_to "http://myredirect"
	assert_equal 4, session[:user_id]

	post :login, {:user => {:w3login => "abc@def.ghi", :w3pass => "wrongpass"}, :redirect => "http://myredirect"}
	assert_response :success, @response.body
	assert flash.has_key?(:notice)
	assert_equal "Login failed. Please check your password and try again.", flash[:notice]
  end
   def test_blacklist
      Blacklist.create(:ip_address=>@request.remote_addr)
      get :home
      assert_response 406,@response.body
      assert_tag :tag => "a", :content => $profile.site_email
   end

   def test_login_wording
     do_ssl_request
     get :login
     assert_tag :tag => "div",
       :content =>
     "\nPlease log in with your #{$profile.id_name} and password.\n"
   end

   def test_login_no_ssl
     @request = ActionController::TestRequest.new if @request.nil?
     @request.env['HTTPS'] = 'off'
     get :login
     assert_response :redirect, @response.body
     assert_redirected_to({ :controller => "login", :action => "login", :protocol => "https://" })
   end

   private 
   def do_ssl_request
     @request = ActionController::TestRequest.new if @request.nil?
     @request.env['HTTPS'] = 'on'
   end 
end
