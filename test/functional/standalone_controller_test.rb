# (C) Copyright IBM Corp. 2010
require File.dirname(__FILE__) + '/../test_helper'
require 'standalone_controller'
require 'digest/sha1'

# Re-raise errors caught by the controller.
class StandaloneController; def rescue_action(e) raise e end; end

class StandaloneControllerTest < ActionController::TestCase
	def setup
		@controller = StandaloneController.new
		@request    = ActionController::TestRequest.new
		@response   = ActionController::TestResponse.new
		$profile = StandaloneProfile.new
	end

	# ----------------------------------------------------------------------
	def test_newuser_form
		get :newuser
		assert_response :success, @response.body
	end

	def test_createuser
		email = "abc@123.com"
		pass = "mypass"
		redirect = "http://my.com"
		post :newuser, { :user => {:email => email, :password => pass}, :redirect => redirect }
		assert_response 302, @response.body
		assert_redirected_to redirect
		d = Digest::SHA1.new
		d.update(pass)
		digest = d.hexdigest
		p = StandaloneUser.find(:all, :conditions => { :email => email, :password => digest })
		assert_equal 1, p.length
		assert_equal email, p[0].email
		assert_equal digest, p[0].password
	end

	def test_register_standalone_already_exists
		# this should fail because the user has already registered
	    post :newuser, {:user => {:email => "abc@def.ghi", :password => "newpass"}}
		assert_response :success, @response.body
		assert flash.has_key?(:notice)
		assert_equal "This email address has already been registered", flash[:notice]
	end

   def test_blacklist
      Blacklist.create(:ip_address=>@request.remote_addr)
      get :home
      assert_response 406,@response.body
      assert_tag :tag => "a", :content => $profile.site_email
   end
end
