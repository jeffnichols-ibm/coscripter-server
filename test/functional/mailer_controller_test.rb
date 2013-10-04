# (C) Copyright IBM Corp. 2010
require File.dirname(__FILE__) + '/../test_helper'
require 'mailer_controller'

# Re-raise errors caught by the controller.
class MailerController; def rescue_action(e) raise e end; end

class MailerControllerTest < ActionController::TestCase
  def setup
    @controller = MailerController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @emails     = ActionMailer::Base.deliveries
    @emails.clear
  end

  # Replace this with your real tests.
  def test_unsub
    me = Person.find(1)
	assert_equal false, me.optout
	get :unsub, {}, { :user_id => me.id }
	assert_response :success, @response.body
	me = Person.find(1)
	assert_equal true, me.optout
	assert_equal "You have been unsubscribed from the CoScripter Newsletter.", @response.body.strip
  end
   def test_blacklist
      Blacklist.create(:ip_address=>@request.remote_addr)
      get :home
      assert_response 406,@response.body
      assert_tag :tag => "a", :content => $profile.site_email
   end
   def test_newsletter
     tessa = people(:tessa)
     execution_time = Time.now.utc
     procedure = procedures(:first)
     p=ProcedureExecute.create(
       :procedure => procedure,
       :person => tessa.friends[0],
       :executed_at => execution_time
     )
     procedure.usagecount += 1
     procedure.last_executed_at=execution_time
     procedure.save

     get :send_newsletter_to, :id=>tessa.email
     email = @emails.first  # @emails contains the emails sent during the test
     today = Time.now.strftime("%d %b")
     assert_equal "CoScripter newsletter for #{today}",email.subject
     assert_equal "multipart/alternative",email.content_type 
     assert_equal tessa.email,email.to[0]
     assert_equal "text/html",email.parts[0].content_type
     assert_match "Greetings from CoScripter!",email.parts[0].body
     # could test actual content like the fact that tessas friend executed a script just now
   end
end
