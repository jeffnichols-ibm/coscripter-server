# (C) Copyright IBM Corp. 2010
require File.dirname(__FILE__) + '/../test_helper'
require 'api_controller'

# Re-raise errors caught by the controller.
class ApiController; def rescue_action(e) raise e end; end

class ApiControllerTest < ActionController::TestCase
 
  def setup
    @controller = ApiController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @tessa = Person.find(1)
    @jimmy = Person.find(2)
    @allen = Person.find(5)
    @privproc = Procedure.find(7)
    $profile = TestProfile.new

    # Set up mailer
    ActionMailer::Base.deliveries = []
    ActionMailer::Base.delivery_method = :test
  end

  # ----------------------------------------------------------------------
  def test_person
    @request.session[:user_id] = @tessa.id
    # make sure we get all this person's scripts even if they have more
    # than 20 (the limit on how many the API will return by default)
    get :person, {:id => @tessa.shortname, :limit => -1}
    assert_response :success
    ret = JSON.parse(@response.body)
    assert_equal @tessa.procedures.length, ret.length
    procs = @tessa.procedures.find(:all, :order => "modified_at DESC")
    procs.each_index {|i|
      assert_equal procs[i].title, ret[i]['title']
      assert_equal @tessa.email, ret[i]['creator']['email']
      assert_equal procs[i].private, ret[i]['private']
    }
  end

  def test_limit
    @request.session[:user_id] = @tessa.id
    get :person, {:id => @tessa.shortname, :limit => 1}
    assert_response :success, @response.body
    ret = JSON.parse(@response.body)
    assert_equal 1, ret.length

    @request.session[:user_id] = @tessa.id
    get :person, {:id => @tessa.shortname, :limit => 4}
    assert_response :success, @response.body
    ret = JSON.parse(@response.body)
    assert_equal 4, ret.length

    @request.session[:user_id] = @tessa.id
    get :person, {:id => @tessa.shortname, :limit => -1}
    assert_response :success, @response.body
    ret = JSON.parse(@response.body)
    assert_equal @tessa.procedures.length, ret.length
  end

  def test_person_private
    @request.session[:user_id] = @jimmy.id
    get :person, {:id => @tessa.shortname}
    assert_response :success, @response.body
    ret = JSON.parse(@response.body)
    assert_not_equal @tessa.procedures.length, ret.length
    ret.each {|p|
      assert_not_equal "A private procedure", p['title']
      assert_not_equal "Editor pick that is also private", p['title']
    }
  end

  def test_editors_picks
    get :editorspicks
    assert_response :success, @response.body
    ret = JSON.parse(@response.body)
    titles = ret.collect { |p| p['title']}
    assert titles.include?("Second Procedure, Editors' Pick")
    assert !(titles.include? "Editor pick that is also private")

    @request.session[:user_id] = @tessa.id
    get :editorspicks
    assert_response :success, @response.body
    ret = JSON.parse(@response.body)
    titles = ret.collect { |p| p['title']}
    assert titles.include?("Editor pick that is also private")
  end

  def test_popular
    get :scripts, :sort => 'usage'
    assert_response :success, @response.body

    @request.session[:user_id] = @jimmy.id
    get :scripts, :sort => 'usage'
    assert_response :success, @response.body
  end

  def test_procedure
    get :procedure, {:id => 1}
    assert_response 401, @response.body

    @request.session[:user_id] = @jimmy.id
    get :procedure, {:id => 1}
    assert_response :success, @response.body
    ret = JSON.parse(@response.body)
    script = Procedure.find(1)
    assert_equal ret['title'], script.title
    assert_equal ret['creator']['email'], script.person.email
    assert_equal ret['session_user']['email'], @jimmy.email

    @request.session[:user_id] = @jimmy.id
    get :procedure, {:id => @privproc.id}
    assert_response 404, @response.body

    @request.session[:user_id] = @tessa.id
    get :procedure, {:id => @privproc.id}
    assert_response :success, @response.body
    ret = JSON.parse(@response.body)
    assert_equal @privproc.title, ret['title']
    assert_equal @privproc.body, ret['body']
    assert_equal @privproc.id, ret['id']

    # a script that shouldn't exist
    @request.session[:user_id] = @jimmy.id
    get :procedure, {:id => 1024}
    assert_response 404, @response.body
  end

  # ----------------------------------------------------------------------
  def test_byurl
    get :byurl, {:q => 'about:blank'}
    assert_response :success, @response.body
    get :byurl, {:q => 'about:blank', :callback => 'foo'}
    assert_response :success, @response.body
    assert_equal 'foo([])', @response.body
    get :byurl, {:q => 'about:blank', :callback => 'foo', :limit => 10}
    assert_response :success, @response.body
  end

  # ----------------------------------------------------------------------
  def test_store_authenticated
    @request.session[:user_id] = 1
    get :store, {:id => 'doesnotexist'}
    assert_response :success, @response.body
    assert_equal '{"value":""}', @response.body

    get :store, {:id => 'teststore'}
    assert_response :success, @response.body
    assert_equal '{"value":"testvalue"}', @response.body
  end

  def test_store_unauthenticated
    get :store, {:id => "doesnotexist"}
    assert_response 401, @response.body

    post :store, {:id => "doesnotexist"}
    assert_response 401, @response.body
  end

  def test_store_post
    @request.session[:user_id] = 1
    post :store, {:id => "newstore", :value => "newvalue"}
    assert_response :success, @response.body
    userdata = UserData.find_by_person_id_and_name(1, "newstore")
    assert_equal "newvalue", userdata.value
    get :store, {:id => "newstore"}
    assert_equal '{"value":"newvalue"}', @response.body

    # now try a second post
    post :store, {:id => "newstore", :value => "other value"}
    assert_response :success, @response.body
    userdata = UserData.find_by_person_id_and_name(1, "newstore")
    assert_equal "other value", userdata.value
    get :store, {:id => "newstore"}
    assert_equal '{"value":"other value"}', @response.body
  end

  def test_find_approximate
    get :find_approximate, {:terms => "google search"}
    assert_response :success, @response.body
    procs = JSON.parse(@response.body)
    assert_equal 3, procs.length
    assert_equal "First Procedure", procs[0]['title']
#    assert_equal "http://koala.almaden.ibm.com/koala/browse/procedure/1",
#      procs[0]['koalescence-url']
    assert_equal "A third three-step procedure", procs[1]['title']
    assert_not_nil procs[0]['json-url']

    # also try with POST
    post :find_approximate, {:terms => "google search"}
    assert_response :success, @response.body
  end

  def test_create_public
    @request.session[:user_id] = @tessa.id
    title = "New private script"
    post :procedure, {:title => title, :private => 'false', :body => "* step 1"}
    assert_response :success, @response.body
    ret = JSON.parse(@response.body)
    scriptid = ret['id']
    script = Procedure.find(scriptid)
    assert_equal false, script.private
    assert_equal title, script.title
  end

  def test_create_private_unspecified
    @request.session[:user_id] = @tessa.id
    title = "New script"
    post :procedure, {:title => title, :body => "* step 1"}
    assert_response :success, @response.body
    ret = JSON.parse(@response.body)
    scriptid = ret['id']
    script = Procedure.find(scriptid)
    # scripts aren't private by default
    assert_equal false, script.private?
    assert_equal title, script.title
  end

  def test_create_private
    @request.session[:user_id] = @tessa.id
    title = "New private script"
    post :procedure, {:title => title, :private => 'true', :body => "* step 1"}
    assert_response :success, @response.body
    ret = JSON.parse(@response.body)
    assert_equal true, ret['private']
    scriptid = ret['id']
    script = Procedure.find(scriptid)
    assert_equal true, script.private?
    assert_equal title, script.title
  end

  def test_unicode
    @request.session[:user_id] = @tessa.id
    get :procedure, {:id => 10}
    assert_response :success, @response.body
    ret = JSON.parse(@response.body)
    assert_equal "Iñtërnâtiônàlizætiøn title", ret['title']
  end

  def test_noauthor
    post :procedure, {:title => 'my title', :body => 'my body'}
    assert_response :unauthorized, @response.body

    @request.session[:user_id] = @tessa.id
    post :procedure, {:title => 'my title', :body => 'my body'}
    assert_response :success, @response.body
    ret = JSON.parse(@response.body)
    procid = ret['id']
    script = Procedure.find(procid)
    assert_equal @tessa, script.person
  end

  def test_set_private_not_your_own
    # you shouldn't be able to set a script as private unless you own it
    # yet you need to be able to update others' scripts

    # you can send along :private => false because that doesn't change the
    # value
    @request.session[:user_id] = @jimmy.id
    post :procedure, {:id => 11, :title => "New title", :private => 'false'}
    assert_response :success, @response.body

    # but you should get an error if you try to change the value
    @request.session[:user_id] = @jimmy.id
    post :procedure, {:id => 11, :title => "New title", :private => 'true'}
    assert_response :error, @response.body
    assert_equal "Error: Only script creator can update private flag",
      @response.body
  end

  def test_executed
    # Jimmy runs Tessa's script
    @request.session[:user_id] = @jimmy.id
    procedure=Procedure.find(1)
    assert_equal 0,procedure.usagecount
    post :executed,{:id => procedure.id }
    assert_response :success, @response.body
    p = ProcedureExecute.find_all_by_procedure_id_and_person_id(1, @jimmy.id)
    procedure=Procedure.find(1)
    assert_equal 1, p.length
    assert_equal 1, procedure.usagecount
    assert_equal p[0].executed_at,procedure.last_executed_at
    assert_equal p[0].executed_at,procedure.most_recent_usage
  end

  def test_person_last_active_at
    @request.session[:user_id] = @jimmy.id
    procedure=Procedure.find(1)
    post :executed,{:id => procedure.id }
    assert_response :success, @response.body
    usage_log = SiteUsageLog.find(:first, :order=> "id desc")
    jimmy=Person.find(2)
    assert_equal jimmy.id, usage_log.person.id
    assert_equal "executed", usage_log.action
    assert_equal "/api/executed/1",usage_log.uri 
    assert_equal jimmy.last_active_at,usage_log.accessed_at
  end

  def test_person_last_active_at_with_ping
    @request.session[:user_id] = @jimmy.id
    get :ping
    jimmy=Person.find(2)
    assert_response :success, @response.body
    usage_log = SiteUsageLog.find(:first, :order=> "id desc")
    assert_equal jimmy.id, usage_log.person.id
    assert_equal "ping", usage_log.action
    assert_equal jimmy.last_active_at,usage_log.accessed_at
    assert_equal "/api/ping",usage_log.uri 
   end


  def test_recently_touched_smoketest
    @request.session[:user_id] = @tessa.id
    get :recently_touched
    assert_response :success, @response.body
  end

  def test_recently_touched_limit
    @request.session[:user_id] = @tessa.id
    get :recently_touched, { :limit => "-1" }
    assert_response :success, @response.body
  end

  def test_person_not_logged_in
    # new version; tell it our version in the HTTP headers
    @request.env['HTTP_COSCRIPTERVERSION'] = '1.391'
    get :person
    assert_response 401, @response.body
    assert_equal "Unable to authenticate using your test id and password\n", @response.body

    # the old version is no longer supported; it should also return a 401
    # even through the old extension doesn't know what to do with that.
    # People with old versions of the extension need to upgrade them.
    @request.env['HTTP_COSCRIPTERVERSION'] = '1.388'
    get :person
    assert_response 401, @response.body
    assert_equal "Unable to authenticate using your test id and password\n", @response.body
  end

  def test_touched_not_logged_in
    get :recently_touched
    assert_response 401, @response.body
    assert_equal "Unable to authenticate using your test id and password\n", @response.body
  end

  def test_byurl_aa_com
    get :byurl, { :q => "http://www.aa.com/index_us.jhtml" }
    assert_response :success, @response.body
    ret = JSON.parse(@response.body)
    assert_equal 1, ret.length
    assert_equal "Check American Airlines", ret[0]['title']
  end

    # ----------------------------------------------------------------------
    # Changelogs
    def test_changelog_creation_on_new_script
        @request.session[:user_id] = @tessa.id
        post :script, { :title => "First script post", :body => "no body here" }
        assert_response :success, @response.body
        ret = JSON.parse(@response.body)
        scriptid = ret['id']
        ch = Change.find_all_by_procedure_id(scriptid)
        assert_equal 1, ch.length
        assert_equal "First script post", ch[0].title
        assert_equal "no body here", ch[0].body
        assert_nil ch[0].log
        assert_equal "NEW SCRIPT", ch[0].syslog

        # should not send email because I changed my own script
        assert_equal 0, ActionMailer::Base.deliveries.length
    end

    def test_changelog_on_update_script
        @request.session[:user_id] = @tessa.id
        post :script, { :title => "Script update", :body => "", :changelog =>
            "removed the body", :id => 21 }
        assert_response :success, @response.body

        ch = Change.find_all_by_procedure_id(21)
        assert_equal 1, ch.length
        assert_equal "removed the body", ch[0].log
    end

    # ----------------------------------------------------------------------
    # Sending email on script updates

    def test_email_sending_on_script_update
        @request.session[:user_id] = @allen.id
        post :script, {:title => "Script change", :body => "allen script body", :id => 24 }
        assert_response :success, @response.body

        # make sure it sent mail to Tessa
        assert_equal 1, ActionMailer::Base.deliveries.length
        sent = ActionMailer::Base.deliveries.first
        assert_equal [@tessa.email], sent.to
        assert sent.body =~ /Allen Cypher has modified one of your scripts./, sent.body
        assert sent.body =~ /allen script body/, sent.body
    end

    def test_email_send_to_all_contributors
        @request.session[:user_id] = @jimmy.id
        post :script, {:title => "Script change", :body => "jimmy script body", :id => 23 }
        assert_response :success, @response.body

        # make sure it sent mail to Tessa and Allen
        assert_equal 2, ActionMailer::Base.deliveries.length
        sent1 = ActionMailer::Base.deliveries[0]
        assert_equal [@tessa.email], sent1.to
        assert sent1.body =~ /Jimmy Lin has modified one of your scripts./, sent1.body
        assert sent1.body =~ /jimmy script body/, sent1.body
        assert_equal ["test@testdomain.com"], sent1.from
        sent2 = ActionMailer::Base.deliveries[1]
        assert_equal [@allen.email], sent2.to
        assert sent2.body =~ /Jimmy Lin has modified a script you have contributed to./, sent2.body
        assert sent2.body =~ /jimmy script body/, sent2.body
        assert_equal ["test@testdomain.com"], sent2.from
    end

    def test_noemail
        $profile = TestProfileNoemail.new
        
        @request.session[:user_id] = @allen.id
        post :script, {:title => "Script change", :body => "allen script body", :id => 24 }
        assert_response :success, @response.body

        # make sure it sent no email
        assert_equal 0, ActionMailer::Base.deliveries.length
    end

    def test_noemail2
        $profile = TestProfileNoemail.new
        @request.session[:user_id] = @jimmy.id
        post :script, {:title => "Script change", :body => "jimmy script body", :id => 23 }
        assert_response :success, @response.body

        # make sure it sent no email
        assert_equal 0, ActionMailer::Base.deliveries.length
    end

    # ----------------------------------------------------------------------

  def test_testcase_generation
    @request.session[:user_id] = @tessa.id
    post :testcase, {:url => "http://google.com",
      :xpath => "/HTML[1]/BODY[1]/DIV[1]/NOBR[1]/SPAN[2]/A[1]",
      :slop => "click the News link",
      :act => "click"}
    assert_response :success, @response.body
    ret = JSON.parse(@response.body)
    tc = Testcase.find(ret['id'])
    assert_equal "click", tc.action
    assert_equal "/HTML[1]/BODY[1]/DIV[1]/NOBR[1]/SPAN[2]/A[1]", tc.target
    assert_equal "click the News link", tc.slop
  end

  def test_named_testcase
    @request.session[:user_id] = @tessa.id
    post :testcase, {:url => "http://google.com",
      :xpath => "/HTML",
      :slop => "click the HTML link",
      :name => "Click test on google"
      }
    assert_response :success, @response.body
    ret = JSON.parse(@response.body)
    tc = Testcase.find(ret['id'])
    assert_equal "Click test on google", tc.name
    assert_equal "/HTML", tc.target
    assert_equal "click the HTML link", tc.slop

    @request.session[:user_id] = @tessa.id
    get :testcase, {:id => ret['id']}
    assert_response :success, @response.body
    ret2 = JSON.parse(@response.body)
    assert_equal "Click test on google", ret2['name']
    assert_equal "/HTML", ret2['xpath']
    assert_equal "click the HTML link", ret2['slop']
  end

  def test_overwrite_testcase
    @request.session[:user_id] = @tessa.id
    post :testcase, {:url => "http://yahoo.com", :xpath => "/html",
      :slop => "click the HTML link",
      :id => 1}
    assert_response :success, @response.body
    tc = Testcase.find(1)
    assert_equal "http://yahoo.com", tc.url
    assert_equal "/html", tc.target
  end
 
  def test_delete_testcase
    # normal case
    @request.session[:user_id] = @tessa.id
    delete :testcase, { :id => 99}
    assert_response :success, @response.body

    # trying to delete non existent testcase -> Error 404
    @request.session[:user_id] = @tessa.id
    delete :testcase, { :id => 10}
    assert_response 404, @response.body

    # trying to delete as non admin
    @request.session[:user_id] = @jimmy.id #jimmy is not an admin 
    delete :testcase, { :id => 1 }
    assert_response 403, @response.body
    assert Testcase.find(1).valid?

    # trying to delete without being logged in
    @request.session[:user_id] = nil 
    delete :testcase, { :id => 1 }
    assert_response 401, @response.body
    assert Testcase.find(1).valid?
  end

  def test_testcases_sorted
    @request.session[:user_id] = @tessa.id
    get :testcase
    assert_response :success, @response.body
    ret = JSON.parse(@response.body)
    assert_equal 1, ret[0]['id']
    assert_equal 2, ret[1]['id']
    assert_equal 3, ret[2]['id']
  end

  def test_ping
    get :ping
    assert_response :success, @response.body
    ret = JSON.parse(@response.body)
    assert ret.include?('coscripter-login-url')
    assert ret.include?('coscripter-favorite-url')
    assert_equal "http://test.host/browse/home", ret['coscripter-favorite-url']
  end

  def test_usagelog_no_person
    post :usagelog, {:event => 123, :extra => "my extra string"}
    assert_response :success, @response.body
  end

  def test_favorites
    @request.session[:user_id] = nil
    get :favorites
    assert_response :unauthorized, @response.body

    @request.session[:user_id] = @tessa.id
    get :favorites
    assert_response :success, @response.body
    ret = JSON.parse(@response.body)
    assert_equal 2, ret.length
    assert_equal 18, ret[0]['id']
    assert_equal 16, ret[1]['id']
  end

  def test_byurl
    get :byurl, {:q => "http://google.com"}
    assert_response :success, @response.body
    ret = JSON.parse(@response.body)
    assert_equal 3, ret.length

  end
  
  def test_byurl_older_clients
    # older clients (< 1.700 request byurl too often and cause too much load on the server, hence we won't reqturn results for them)
    @request.env['HTTP_COSCRIPTERVERSION'] = '1.600'
    get :byurl, {:q => "http://google.com"}
    assert_response :success, @response.body
    ret = JSON.parse(@response.body)
    assert_equal 0, ret.length
  end

  def test_byurl_newer_clients
    @request.env['HTTP_COSCRIPTERVERSION'] = '1.700'
    get :byurl, {:q => "http://google.com"}
    assert_response :success, @response.body
    ret = JSON.parse(@response.body)
    assert_equal 3, ret.length
  end

  def test_find_with_step
    get :find_with_step, {:step => "go to google.com"}
    assert_response :success, @response.body
    ret = JSON.parse(@response.body)
    assert_equal 3, ret.length
  end

  def test_allscripts
    get :scripts, {:sort => "favorite", :limit => -1}
    assert_response :success, @response.body
    ret = JSON.parse(@response.body)
    Procedure.with_privacy(nil) {
        numscripts = Procedure.procedures_sorted_by('favorite',nil,-1).length
        assert_equal numscripts, ret.length
    }

    get :scripts, {:sort => "usage", :limit => -1}
    assert_response :success, @response.body
    ret = JSON.parse(@response.body)
    Procedure.with_privacy(nil) {
        numscripts = Procedure.count
        assert_equal numscripts, ret.length
    }
  end

  def test_sloplines_admin
    @request.session[:user_id] = @jimmy.id
    get :sloplines
    assert_response 403, @response.body

    @request.session[:user_id] = @tessa.id
    get :sloplines
    assert_response :success, @response.body
  end

  def test_mytag
    # get all the scripts that I have tagged "foo"
    @request.session[:user_id] = @tessa.id
    get :mytag, :id => "foo"
    assert_response :success, @response.body
    ret = JSON.parse(@response.body)
    assert_equal 3, ret.length
    ids = ret.collect { |p| p['id'] }
    assert ids.include?(3)
    assert ids.include?(7)
    assert ids.include?(18)
  end

  def test_alltags
    @request.session[:user_id] = @tessa.id
    get :alltags, :id => "foo"
    assert_response :success, @response.body
    ret = JSON.parse(@response.body)
    assert_equal 4, ret.length
    ids = ret.collect { |p| p['id'] }
    assert ids.include?(3)
    assert ids.include?(4)
    assert ids.include?(7)
    assert ids.include?(18)
  end

  def test_multiple_tags_in_alltags
    @request.session[:user_id] = @tessa.id
    get :alltags, :id => "bar baz"
    assert_response :success, @response.body
    ret = JSON.parse(@response.body)
    assert_equal 1, ret.length
    ids = ret.collect { |p| p['id'] }
    assert ids.include?(19)
  end

  def test_multiple_tags_in_mytags
    @request.session[:user_id] = @tessa.id
    get :mytag, :id => "bar baz"
    assert_response :success, @response.body
    ret = JSON.parse(@response.body)
    assert_equal 1, ret.length
    ids = ret.collect { |p| p['id'] }
    assert ids.include?(19)
  end

  def test_script_tag
    @request.session[:user_id] = @tessa.id
    post :script, { :title => "myscript", :body => "mybody", :tags => "cotest" }
    assert_response :success, @response.body
    ret = JSON.parse(@response.body)
    scriptid = ret['id']
    p = Procedure.find(scriptid)
    assert_equal 1, p.tags.length
    assert_equal "cotest", p.tags[0].raw_name
  end

  def test_private_script_via_api
    @request.session[:user_id] = nil
    get :script, {:id => 7}
    assert_response 404, @response.body
    assert_equal "Either this script does not exist, or you do not have permission to view it", @response.body
  end

  def test_private_script_requested_by_owner
    @request.session[:user_id] = @tessa.id
    get :script, {:id => 7}
    assert_response :success, @response.body
    ret = JSON.parse(@response.body)
    assert_equal 7, ret['id']
    assert_equal "A private procedure", ret['title']
  end

  def test_pos_tagger
    get :postag, { :q => "search for flights" }
    assert_response :success, @response.body
    ret = JSON.parse(@response.body)
    assert_equal ["search", "for", "flights"], ret['tokens']
    # TL: fake the data until we get a real POS tagger
    #assert_equal ["NN", "IN", "NNS"], ret['tags']
    assert_equal ["NN", "NN", "NN"], ret['tags']
  end

  def test_unauthenticated_script_creation
    post :savescript, {:body => "my body", :title => "my new script"}
    assert_response 401, @response.body

    post :script, {:body => "my body", :title => "my new script"}
    assert_response 401, @response.body
    assert_equal "Unable to authenticate using your test id and password\n", @response.body
  end

  def test_authenticated_script_creation
    @request.session[:user_id] = @tessa.id
    post :savescript, {:body => "my body", :title => "my new script"}
    assert_response :success, @response.body
  end

  def test_alltags_no_tag
    @request.session[:user_id] = @tessa.id
    get :alltags
    assert_response :success, @response.body
  end

  def test_blacklist
    Blacklist.create(:ip_address=>@request.remote_addr)
    get :home
    assert_response 406,@response.body
    assert_tag :tag => "a", :content => $profile.site_email
  end

  def test_scratch_space
    @request.session[:user_id] = @tessa.id
    before = ScratchSpace.count(:all)
    put :scratch_space, :title => "My title", :tablesJson => "[]"
    assert_response :success, @response.body
    ret = JSON.parse(@response.body)
    id = ret['id']
    after = ScratchSpace.count(:all)
    assert_equal before + 1, after

    space = ScratchSpace.find(id)
    assert_not_nil space

    post :delete_scratch_space, :id => id
    assert_response :success, @response.body
    assert_equal "Scratch space deleted", @response.body
    after2 = ScratchSpace.count(:all)
    assert_equal before, after2
  end

  def test_whoami
     @request.session[:user_id] = @tessa.id
     get :whoami
     assert_response :success, @response.body
   end

  def test_creating_script_noauth
    @request.session[:user_id] = nil
    post :script, { :title => "My script", :body => "no body" }
    assert_response :unauthorized, @response.body
  end

  def test_savescript_noauth
    @request.session[:user_id] = nil
    post :savescript, { :title => "My script", :body => "no body" }
    assert_response :unauthorized, @response.body
   end

  # ----------------------------------------------------------------------
  def test_scripts_if_modified_since
    @request.session[:user_id] = @jimmy.id
    now = Time.now + 5.minutes
    @request.env['HTTP_IF_MODIFIED_SINCE'] = now.to_s
    get :person, {:id => @tessa.shortname, :limit => -1}
    assert_response 304, @response.body
    assert_equal "", @response.body.strip
  end

  # ----------------------------------------------------------------------
  def test_coco_api
    @request.session[:user_id] = @jimmy.id
    now = Time.now + 5.minutes
    @request.env['HTTP_IF_MODIFIED_SINCE'] = now.to_s
    get :coco, {:id => @jimmy.shortname}
    assert_response 304, @response.body
    assert_equal "", @response.body.strip
  end
end
