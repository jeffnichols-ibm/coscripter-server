# (C) Copyright IBM Corp. 2010
require File.dirname(__FILE__) + '/../test_helper'
require 'browse_controller'
require 'bluepages-profile'
require 'test-profile'
require 'test-profile-noemail'

# Re-raise errors caught by the controller.
class BrowseController; def rescue_action(e) raise e end; end

class BrowseControllerTest < ActionController::TestCase

  def setup
    @controller = BrowseController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @tessa = Person.find(1)
    @jimmy = Person.find(2)
    @allen = Person.find(5)
    @p1 = Procedure.find(1)
    @privproc = Procedure.find(7)

  # Set up mailer
  ActionMailer::Base.deliveries = []
  ActionMailer::Base.delivery_method = :test

  $profile = TestProfile.new
  end

  # Test visual components

  def test_recent_with_privacy
    get :scripts, {:sort => 'modified'}, {:user_id => @jimmy.id}
    most_recent = Procedure.find(:all,
      :order => "modified_at desc",
      :conditions => ["private = false or person_id = ?",
        @jimmy.id])
    assert_no_tag :tag => "a", :content => "A private procedure"
    assert_tag :tag => "a", :content => most_recent[0].title
    assert_tag :tag => "a", :content => most_recent[1].title

    get :scripts, {:sort => 'modified'}, {:user_id => @tessa.id}
    most_recent = Procedure.find(:all,
      :order => "modified_at desc",
      :conditions => ["private = false or person_id = ?",
        @tessa.id])
    assert_tag :tag => "a", :content => most_recent[0].title
    assert_tag :tag => "a", :content => most_recent[1].title
    assert_tag :tag => "a", :content => most_recent[2].title
  end

  def test_popular_with_privacy
    get :scripts, {:sort => 'usage'}, {:user_id => @jimmy.id}
    assert_response :success
    assert_no_tag :tag => "a", :content => "A private procedure"
  end

  def test_myscripts_with_privacy
    get :person, {:id => $profile.shortname_for_person(@tessa)}, {:user_id => @jimmy.id}
    assert_no_tag :tag => "a", :content => "A private procedure"
    # but when Tessa requests her scripts, she sees the private one
    get :person, {:id => $profile.shortname_for_person(@tessa)}, {:user_id => @tessa.id}
    assert_tag :tag => "a", :content => "A private procedure"
  end

  def test_search_with_privacy
    # the private procedure should come up when I search, but not when
    # jimmy or anonymous searches
    get :search, {:q => "private"}, {:user_id => @tessa.id}
    assert_tag :tag => "a", :content => "A private procedure"

    get :search, {:q => "private"}, {:user => nil}
    assert_no_tag :tag => "a", :content => "A private procedure"
    get :search, {:q => "private"}, {:user_id => @jimmy.id}
    assert_no_tag :tag => "a", :content => "A private procedure"
  end

  def test_scriptview_with_privacy
    get :script, {:id => 7}, {:user_id => @tessa.id}
    assert_tag :tag => "h1", :content => "A private procedure",
      :parent => { :tag => "div", :attributes =>
        {:class => "proc_header_private"}}

    get :script, {:id => 7}, {:user_id => @jimmy.id}
    assert_tag :tag => "div",
      :content => /You are not authorized to view this script./
    get :script, {:id => 7}, {:user => nil}
    assert_tag :tag => "div",
      :content => /You are not authorized to view this script./
  end

  def test_editorspick_with_privacy
    get :about, {:user_id => nil}
    assert_response :success
    assert_tag :tag => "a", :content => "Second Procedure, Editors' Pick"
    assert_no_tag :tag => "a", :content => "Editor pick that is also private"
  end

  def test_version
    get :version, {:id => 1}, {:user_id => @tessa.id}
    assert_tag :tag => "p", :content =>
      "original version of private script"
    # make sure changelogs are privacy-protected
    get :version, {:id => 1}, {:user_id => @jimmy.id}
    assert_equal "You are not authorized to view this version",
      @response.body
    get :version, {:id => 1000}, {:user_id => @jimmy.id}
    assert_equal "The requested version does not exist",
      @response.body
  end

  def test_lastedit_null
    # script #9 was last edited by someone who should not exist
    get :script, {:id => 9}
    assert_response :success
  end

  def test_changelog_null_author
    get :versions, {:id => 9}
    assert_response :success
  end

  def test_unicode_script
    get :script, {:id => 10}
    assert_response :success
    assert_tag :tag => "h1", :content => "Iñtërnâtiônàlizætiøn title"
  end

  def test_oldurls
    # these urls used to work ... make sure they redirect you to reasonable
    # ones now and in the future
    get :recent
    assert_response :redirect
    assert_redirected_to :controller => 'browse', :action => 'scripts',
      :sort => 'modified'

    get :popular
    assert_response :redirect
    assert_redirected_to :controller => 'browse', :action => 'scripts',
      :sort => 'usage'
  end

  def test_site_usage_log
    @request.session[:user_id] = @tessa.id
    @request.env['HTTP_COSCRIPTERVERSION'] = "1.700"
    get :scripts
    assert_response :success
    usage_log = SiteUsageLog.find(:first, :limit =>1, :order=> "id desc")
    assert_equal @tessa.id, usage_log.person.id
    assert_equal "scripts", usage_log.action
    assert_equal "/browse/scripts",usage_log.uri 
    assert_equal "1.700", usage_log.client_version
  end

  def test_site_usage_log_no_client_version
    @request.session[:user_id] = @tessa.id
    get :scripts
    assert_response :success
    usage_log = SiteUsageLog.find(:first, :limit =>1, :order=> "id desc")
    assert_equal @tessa.id, usage_log.person.id
    assert_equal "scripts", usage_log.action
    assert_equal "/browse/scripts",usage_log.uri 
    assert_nil usage_log.client_version
  end


  def test_person_last_active_at
    @request.session[:user_id] = @tessa.id
    get :scripts
    assert_response :success
    usage_log = SiteUsageLog.find(:first, :limit =>1, :order=> "id desc")
    tessa = Person.find(1)
    assert_equal tessa.id, usage_log.person.id
    assert_equal "scripts", usage_log.action
    assert_equal "/browse/scripts",usage_log.uri 
    assert_equal tessa.last_active_at,usage_log.accessed_at
   end

  def test_script_deleted_author
    get :script, {:id => 14}
    assert_response :success
  end

  def test_script_with_comments
    get :script, {:id => 15}
    assert_response :success
  end

  def test_home
    @request.session[:user_id] = @tessa.id
    get :home
    assert_response :success, @response.body
  end

  def test_showcomments
    @request.session[:user_id] = @tessa.id
    get :showcomments
    assert_response :success, @response.body
  end

  def test_person_all_noscripts
    @user_with_no_scripts = Person.find(3)
    assert_equal 0, @user_with_no_scripts.procedures.length
    get :person, {:id => @user_with_no_scripts.shortname, :page => 'all'}
    assert_response :success, @response.body

    get :person, {:id => @user_with_no_scripts.shortname}
    assert_no_tag :tag => "a", :content => "show all"
  end

  def test_person_allscripts
    @request.session[:user_id] = @tessa.id
    get :person, {:id => @tessa.shortname, :page => 'all'}
    assert_response :success, @response.body
    count = @tessa.procedures.length
    assert_tag :tag => "div", :content => /1-#{count} of #{count}/
  end

  def test_person_no_id_no_session
    get :person
    assert_redirected_to :controller => 'browse', :action => 'people'
  end

  def test_person_with_id_no_session
    get :person, {:id => @tessa.shortname}
    assert_response :success, @response.body
    assert_tag :tag => "title", :content =>
      "CoScripter: #{@tessa.name}'s scripts"
  end

  def test_person_no_id_with_session
    @request.session[:user_id] = @tessa.id
    get :person
    assert_redirected_to :controller => 'browse', :action => 'person',
      :id => @tessa.profile_id
  end

  def test_comment_on_my_script
    @request.session[:user_id] = @tessa.id
    post :add_comment, {:comment => 'my comment', :id => 1}
    assert_response :redirect, @response.body
    assert_redirected_to :controller => 'browse', :action => 'script', :id => 1
    assert flash.has_key?(:notice)
    assert_equal "Your comment was added", flash[:notice]
  end

  def test_no_links_in_script_pages
    get :script, {:id => 17}
    assert_response :success, @response.body
    # make sure there is no link to mtv.com in it
    assert_no_tag :tag => "a", :attributes => { :href => "http://www.mtv.com" }
  end

  def test_pagination_no_results
    get :search, {:q => "nonexistentsearchterm", :page => "all"}
    assert_response :success, @response.body
  end

  def test_invalid_page_parameter
    get :search, {:q => "google", :page => "foo"}
    assert_response :success, @response.body
  end

  def test_homepage
    @request.session[:user_id] = nil
    get :index
    assert_template "about"

    @request.session[:user_id] = @tessa.id
    get :index
    assert_template "home"
  end

  def test_wishes
    @request.session[:user_id] = nil
    get :wishlist
    assert_response :success, @response.body
    assert_template "wishlist"
    assert_tag :tag => "h1", :content => "CoScripter Wishlist"

    @request.session[:user_id] = nil
    get :wishlist, { :id => "tessalau@us.ibm.com" }
    assert_response :success, @response.body
    assert_tag :tag => "h1", :content => "Tessa Lau's wishlist"
  end

  def test_comment_on_my_wish
    @request.session[:user_id] = @tessa.id
    post :add_wish_comment, {:comment => 'my comment', :id => 1}
    assert_response :redirect, @response.body
    assert_redirected_to :controller => 'browse', :action => 'wish', :id => 1
    assert flash.has_key?(:notice)
    assert_equal "Your comment was added", flash[:notice]
  end

  def test_wi_no_social_network
    @request.session[:user_id] = @tessa.id
    get :home
    assert_response :success
    assert_no_tag "h1", :content => "Wishes in your social network:"
  end

  def test_dogear_hidden
    get :script, { :id => 1 }
    assert_response :success, @response.body
    assert_no_tag "div", :content => "Post to dogear"
  end

  def test_dogear_visible
    $profile = BluepagesProfile.new
    @request.session[:user_id] = @tessa.id
    get :script, { :id => 1 }
    assert_response :success, @response.body
    assert_tag :tag => "div", :content => "Post to dogear"
  end

  def test_wish_comment
    @request.session[:user_id] = @tessa.id
    get :add_wish_comment, :id => 1, :comment => "test reply to a wish"
    assert_response :redirect, @response.body
    assert_redirected_to :controller => 'browse', :action => 'wish', :id => 1
  end

  def test_delete_wishcomment
    @request.session[:user_id] = @tessa.id
    get :wish, {:id => 1}
    assert_response :success, @response.body
    comment = WishComment.find(1)
    assert_tag "div", :attributes => { "class" => "comment-body" },
      :content => comment.comment
    get :delete_wish_comment, :id => 1
    assert_response :success

    get :wish, {:id => 1}
    assert_response :success, @response.body
    assert_no_tag "div", :attributes => { "class" => "comment-body" },
      :content => comment.comment
  end

  def test_view_network_without_admin
    @request.session[:user_id] = @jimmy.id
    get :view_network
    assert_response 403, @response.body
    assert_equal "You need administrator privileges to use this function",
      @response.body

    @request.session[:user_id] = nil
    get :view_network
    assert_response 403, @response.body
    assert_equal "You need administrator privileges to use this function",
      @response.body

    @request.session[:user_id] = @tessa.id
    get :view_network
    assert_response :success, @response.body
  end

  def test_diff
    get :diff, :id => 6
    assert_response :success, @response.body
    assert_tag :tag => "tr", :attributes => { "class" => "diff" },
      :descendant => { :tag => "td", :content => "line1" }
    assert_tag :tag => "tr", :attributes => { "class" => "diffdeleted" },
      :descendant => { :tag => "td", :content => "line2" }
    assert_tag :tag => "tr", :attributes => { "class" => "diff" },
      :descendant => { :tag => "td", :content => "line3" }
    assert_tag :tag => "tr", :attributes => { "class" => "diff" },
      :descendant => { :tag => "td", :content => "line4" }
    assert_tag :tag => "tr", :attributes => { "class" => "diffadded" },
      :descendant => { :tag => "td", :content => "line5" }
  end

  def test_delete_with_syslog
    @request.session[:user_id] = @tessa.id
    post :delete, :id => 25
    assert_response :redirect, @response.body
    assert_redirected_to :controller => 'browse', :action => :index
    c = Change.find_all_by_procedure_id(25)
    assert_equal 1, c.length
    assert_equal "SCRIPT DELETED", c[0].syslog
  end

  def test_get_copy_page
    @request.session[:user_id] = @jimmy.id
    get :copy, :id => 1
    assert_response :success, @response.body
    assert_tag :tag => "input", :attributes => { "name" => "copyid",
      "value" => "1", "type" => "hidden" }
  end

  def test_copy_with_changelog
    @request.session[:user_id] = @jimmy.id
    post :copy, { :procedure => { :title => "Copied script", :body => "Copy of body" },
      :copyid => "123"}
    newid = Procedure.find(:last).id

    assert_response :redirect, @response.body
    assert_redirected_to :controller => "browse", :action => "script", :id => newid

    ch = Change.find(:first, :order => "modified_at desc")
    assert_equal "Copied script", ch.title
    assert_equal "Copy of body", ch.body
    assert_equal "COPY OF SCRIPT 123", ch.syslog

    p = Procedure.find(ch.procedure_id)
    assert_equal ch, p.changes[0]
  end

  def test_email_on_comments
    @request.session[:user_id] = @allen.id
    post :add_comment, { :comment => "allen comment", :id => 18 }
    assert_response :redirect, @response.body
    assert_redirected_to :controller => 'browse', :action => 'script', :id => 18
    assert flash.has_key?(:notice)
      assert_equal "Comment emailed to Jimmy Lin and Tessa Lau", flash[:notice]

    # Check email deliveries
    assert_equal 2, ActionMailer::Base.deliveries.length
    sent1 = ActionMailer::Base.deliveries[0]
    assert_equal ["jameslin@us.ibm.com"], sent1.to
    assert_equal ["test@testdomain.com"], sent1.from
    sent2 = ActionMailer::Base.deliveries[1]
    assert_equal ["tessalau@us.ibm.com"], sent2.to
    assert_equal ["test@testdomain.com"], sent1.from
  end

  def test_email_on_comments_three_authors
    @request.session[:user_id] = 3
    post :add_comment, { :comment => "another comment", :id => 26 }
    assert_response :redirect, @response.body
    assert_redirected_to :controller => 'browse', :action => 'script', :id => 26
    assert flash.has_key?(:notice)
      assert_equal "Comment emailed to Tessa Lau, Jimmy Lin, and Allen Cypher", flash[:notice]

    # Check email deliveries
    assert_equal 3, ActionMailer::Base.deliveries.length
    sent1 = ActionMailer::Base.deliveries[0]
    assert_equal ["tessalau@us.ibm.com"], sent1.to
    assert_equal ["test@testdomain.com"], sent1.from
    sent2 = ActionMailer::Base.deliveries[1]
    assert_equal ["jameslin@us.ibm.com"], sent2.to
    assert_equal ["test@testdomain.com"], sent1.from
    sent3 = ActionMailer::Base.deliveries[2]
    assert_equal ["acypher@us.ibm.com"], sent3.to
    assert_equal ["test@testdomain.com"], sent3.from
  end

  def test_no_email
    $profile = TestProfileNoemail.new

    @request.session[:user_id] = 3
    post :add_comment, { :comment => "another comment", :id => 26 }
    assert_response :redirect, @response.body
    assert_redirected_to :controller => 'browse', :action => 'script', :id => 26
    assert flash.has_key?(:notice)
      assert_equal "Your comment was added", flash[:notice]

    # Check email deliveries
    assert_equal 0, ActionMailer::Base.deliveries.length
  end

  def test_star
    # When not logged in, you should see a disabled star
    @request.session[:user_id] = nil
    get :script, { :id => 1 }
    assert_response :success, @response.body
    assert_tag :tag => "img", :attributes => { "title" =>
      "Log in to make this script a favorite", "alt" => "Unstar" }

    # When logged in, get a grayed out star
    @request.session[:user_id] = @tessa.id
    get :script, { :id => 1 }
    assert_response :success, @response.body
    assert_tag :tag => "img", :attributes => {"title" => 
      "Mark this script as a favorite", "alt" => "Unstar" }

    # When requesting a favorite, get a lit up star
    @request.session[:user_id] = @tessa.id
    get :script, { :id => 18 }
    assert_response :success, @response.body
    assert_tag :tag => "img", :attributes => {"title" => 
      "Remove this script from my favorites list", "alt" => "Star" }
  end

  def test_star_clicking
    # Test clicking on a star to make it a favorite
    p = Procedure.find(1)
    myfavs = @tessa.favorite_scripts
    assert_equal false, myfavs.include?(p)
    @request.session[:user_id] = @tessa.id

    xml_http_request :post, :set_favorite, { :id => 1 }
    assert_template "_star"

    @tessa.reload
    myfavs = @tessa.favorite_scripts
    assert_equal true, myfavs.include?(p)

    assert_tag :tag => "img", :attributes => {"title" => 
      "Remove this script from my favorites list", "alt" => "Star" }
    assert_no_tag :tag => "img", :attributes => {"title" => 
      "Log in to make this script a favorite" }
  end

  def get *args
    # make sure there's a new SiteUsageLog for every get request
    before= SiteUsageLog.count
    super *args
    after= SiteUsageLog.count
    assert_equal before+1,after
  end

  def post *args
    # make sure there's a new SiteUsageLog for every post request
    before= SiteUsageLog.count
    super *args
    after= SiteUsageLog.count
    assert_equal before+1,after
  end 

  def test_browse_person_wi
    $profile = WiProfile.new
    @request.session[:user_id] = @tessa.id
    get :person
    assert_response :redirect, @response.body
    assert_redirected_to :controller => 'browse', :action => 'person',
      :id => @tessa.name
  end

  def test_browse_person_bluepages
    $profile = BluepagesProfile.new
    @request.session[:user_id] = @tessa.id
    get :person
    assert_response :redirect, @response.body
    assert_redirected_to :controller => 'browse', :action => 'person',
      :id => @tessa.email
  end

  def test_create_new_with_params
    @request.session[:user_id] = @tessa.id
    get :new, { :title => "My new script", :body => "Script body" }
    assert_response :success, @response.body
    assert_tag :tag => "input", :attributes => { "value" => "My new script" }
    assert_tag :tag => "textarea", "content" => "Script body"
  end

  def test_sharing_of_private_script
    @request.session[:user_id] = @tessa.id
    get :script, { :id => 7 }
    assert_response :success, @response.body
    assert_no_tag :tag => "h3", :content => "Sharing"
  end

  def test_acl_add_del
    @request.session[:user_id] = @tessa.id
    p = Procedure.find(7)
    assert_equal 0, p.members.length
    get :acl_add, {:id => 7, :user => "jameslin@us.ibm.com" }
    assert_response :success, @response.body
    p.reload
    assert_equal 1, p.members.length
    assert_equal 2, p.members[0].id

    get :acl_del, {:id => 7, :user => "jameslin@us.ibm.com" }
    assert_response :success, @response.body
    p.reload
    assert_equal 0, p.members.length
  end

  def test_acl_add_person_not_exist
    @request.session[:user_id] = @tessa.id
    p = Procedure.find(7)
    assert_equal 0, p.members.length
    get :acl_add, {:id => 7, :user => "doesnotexist@us.ibm.com" }
                assert_equal "Element.update(\"acl_status\", \"doesnotexist@us.ibm.com is not a CoScripter user\");", @response.body
    p.reload
    assert_equal 0, p.members.length
  end

  def test_acl_private_display
    p = Procedure.find(7)
    assert_equal 0, p.members.length

    @request.session[:user_id] = @jimmy.id
    get :script, {:id => 7}
    assert_response :success, @response.body
    assert_tag :tag => "div", :content => /You are not authorized to view this script./

    p.members << @jimmy
    get :script, {:id => 7}
    assert_response :success, @response.body
    assert_tag :tag => "h3", :content => "Access control"
  end

  def test_acl_private_display_members
    clemens_private_shared_script = procedures(:clemens_private_shared_script)

    @request.session[:user_id] = @jimmy.id
    get :script, {:id => clemens_private_shared_script.id}
    assert_response :success, @response.body
    assert_tag :tag => "h3", :content => "Access control"
    assert_tag :tag => "span", :content => /#{@jimmy.name}/
    assert_tag :tag => "span", :content => /#{@tessa.name}/
    assert_no_tag :tag => "span", :content => /#{@allen.name}/
  end

  def test_all_script_sortings
    @request.session[:user_id] = @jimmy.id
    get :scripts,{:sort=>'popularity'}
    assert_response :success, @response.body
    
    @request.session[:user_id] = @jimmy.id
    get :scripts,{:sort=>'usage'}
    assert_response :success, @response.body

    @request.session[:user_id] = @jimmy.id
    get :scripts,{:sort=>'modified'}
    assert_response :success, @response.body

    @request.session[:user_id] = @jimmy.id
    get :scripts,{:sort=>'creator'}
    assert_response :success, @response.body

    @request.session[:user_id] = @jimmy.id
    get :scripts,{:sort=>'created'}
    assert_response :success, @response.body

  end

  def test_blacklist
    Blacklist.create(:ip_address=>@request.remote_addr)
    get :home
    assert_response 406,@response.body
    assert_tag :tag => "a", :content => $profile.site_email
  end

  def test_unfavorite
    p = Procedure.find(1)
    owner = p.person
    owner.favorite_scripts << p
    assert_equal true, owner.favorite_scripts.include?(p)

    @request.session[:user_id] = p.person.id
    get :unset_favorite, {:id => p.id}
    assert_response :success, @response.body
    
    assert_equal false, owner.favorite_scripts.include?(p)
  end

end
