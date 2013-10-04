# (C) Copyright IBM Corp. 2010

# For diffs
require 'algorithm/diff'
require 'unixdiff'

class BrowseController < ApplicationController
    auto_complete_for :person,:name
    # require admin access for these pages
    before_filter :require_admin, :only => [
        :view_network, :orgs, :org ]

    # require authentication on certain pages
    before_filter :authorize_session, :except => [
    :about, :diff, :index, :people, :person, :popular, :procedure,
    :profile, :recent, :wishlist, :scratch_spaces, :scratch_space, :script, :scripts, :search, :showcomments,
        :tag, :tos, :version, :versions, :video, 
        :maintenance, :scripthistory
        ]

    # the default view.  redirect to the procedures view
    def index
        # enable this for the dynamic home page
        if session[:user_id].nil?
            about
            render :action => "about"
        else
            home
            render :action => "home"
        end
        # default behavior
#        redirect_to :action => 'about'
    end

    # personalized home page
    def home
      Procedure.with_privacy(session[:user_id]) {
        person = logged_in_user()
        @recent = procedures_recently_touched(person)
        @popular =Procedure.procedures_sorted_by("popularity")
        @mycomments = person.recent_procedure_comments(3.months.ago)
        @favorites = person.favorite_scripts
        begin
            @featured_script = FeaturedScript.find(:first,:include => "procedure")
        rescue Exception => e
            @featured_script = nil
        end

        if $profile.profilename == "bluepages"
            @network_activity = person.social_network_activity(:include_self => true)
            @friend_wishes = person.social_network_wishes
            @friend_wishes.sort! { |x, y| y.created_at <=> x.created_at }

            # TODO
            @org_scripts = person.organizational_scripts
        else
            @network_activity = nil
            @friend_wishes = []
            @org_scripts = []
        end

        #@blog = FeedParser.parse($profile.blog_atom_url)
      }
    end

    # ----------------------------------------------------------------------
    # snoop on someone else's social and organizational networks
    def view_network
        Procedure.with_privacy(session[:user_id]) {
            @person = Person.find_by_shortname(params[:id])

            if @person.nil? 
                @org_scripts = []
                @network_activity = []
            else
                @org_scripts = @person.organizational_scripts
                @network_activity = @person.social_network_activity(:include_self => true)
            end
        }
    end

    # ----------------------------------------------------------------------
    # show all a user's comments
    def showcomments
        Procedure.with_privacy(session[:user_id]) {
            commenter = Person.find_by_shortname(params[:id])
            if commenter.nil?
                @comments = []
                @name = params[:id]
            else
                @name = commenter.name
                @comments = commenter.all_procedure_comments
            end
        }
    end

    # ----------------------------------------------------------------------
    # Show scripts with various sort orders

    def scripts
      begin
    Procedure.with_privacy(session[:user_id]) {
      @sortorder = getSortOrder(params[:sort])
      page = params[:page]
      @procedures = Procedure.procedures_sorted_by(@sortorder,page)
      @tagcloud = makeTagcloud(@procedures)
    }
      rescue IndexError => e:
    render :text => "this page does not exist (page index out of bounds)", :status => "404"
      end
    end

    def popular
        # TODO
        redirect_to :action => :scripts, :sort => 'usage'
    end

    def recent
        # TODO
        redirect_to :action => :scripts, :sort => 'modified'
    end

    # display procedures organized by person
    def people
        if params[:id].nil?
            @people = Person.most_popular(:page => params[:page])
             
        else
            @people = Person.paginate(:all,
                                      :select =>"distinct (people.id),people.*",
                                      :joins => "INNER JOIN procedure_executes on ( procedure_executes.person_id = people.id)", 
                                      :page => params[:page],
                                      :conditions=> [ "procedure_executes.procedure_id = ?", params[:id]])
        end
    end

    # display procedures owned by a person
    def person
        Procedure.with_privacy(session[:user_id]) {
            if params[:id].nil? and session[:user_id].nil?
                # sometimes you can get here when you log out from a person page
                # because it will redirect to 'person' with no params[:id]
                redirect_to :action => 'people'
                return
            end

            if params[:id].nil? and not session[:user_id].nil?
                person = Person.find(session[:user_id])
                if not person.nil?
                    # redirect to the logged-in user's person page
                    redirect_to :action => 'person', :id =>
                        $profile.shortname_for_person(person)
                    return
                else
                    # can't find that person in the database even though he has a
                    # session id, so we redirect to people
                    redirect_to :action => 'people'
                    return
                end
            end

            @person = Person.find_by_shortname(params[:id])
            if @person.nil?
                @person = Person.new
                @person.name = params[:id]
                # don't save it!  Just create the record for page display purposes
            end
            find_options =  { :conditions => ['procedures.person_id = ?', @person.id],:order => 'modified_at desc',}
            if params[:page] == "all"
              find_options[:per_page] = 1000000 # bad hack b/c cant get Procedure.count working in this context
              find_options[:page] = 1
            else
              find_options[:page] = params[:page]
            end
            @procedures = Procedure.paginate(find_options)
            @tagcloud = makeTagcloud(@procedures)
        }
    end

  # ----------------------------------------------------------------------

    def scratch_spaces
      ScratchSpace.with_privacy(session[:user_id]) {
        if params[:id].nil?
          @person = nil
          # paginate
          maxprocs = ScratchSpace.count()
          # The +1 below is because the paginator bombs if it's told to use 0
          # maxprocs, so if the person has no scripts, then it will cause a
          # crash.  It should not break existing "show all" functionality
          # because if there are 40 scripts and it puts 41 scripts per page,
          # they will still all show up.
          @scratch_spaces = ScratchSpace.paginate(
            :order => 'updated_at desc',
            :per_page => params[:page] == "all" ? maxprocs + 1 : 20,
            :page => params[:page])
  
          # @tagcloud = makeTagcloud(@scratch_spaces)
        else
          @person = Person.find_by_shortname(params[:id])
          if @person.nil?
            @person = Person.new
            @person.name = params[:id]
            # don't save it!  Just create the record for page display purposes
          end
          
          # paginate
          maxprocs = ScratchSpace.count(:conditions => ['person_id=?', @person.id])
          # The +1 below is because the paginator bombs if it's told to use 0
          # maxprocs, so if the person has no scripts, then it will cause a
          # crash.  It should not break existing "show all" functionality
          # because if there are 40 scripts and it puts 41 scripts per page,
          # they will still all show up.
          @scratch_spaces = ScratchSpace.paginate(
            :conditions => ['person_id = ?', @person.id],
            :order => 'updated_at desc',
            :per_page => params[:page] == "all" ? maxprocs + 1 : 20,
            :page => params[:page])
    
          # @tagcloud = makeTagcloud(@scratch_spaces)
        end
      }
    end
  
    def create_scratch_space
      scratch_space = ScratchSpace.create!(params[:scratch_space])
      
      redirect_to :action => 'scratch_space', :id => scratch_space.id
    end
  
    def create_table_in_scratch_space(scratch_space)
      table = ScratchSpaceTable.create!(
        :scratch_space => scratch_space,
        :title => "Table " + String(scratch_space.scratch_space_tables.length + 1),
        :data_json => [["Col 1", "Col 2", "Col 3"], ["", "", ""], ["", "", ""]].to_json,
        :notes => "")
    end
  
    def create_scratch_space_with_initial_table
      scratch_space = ScratchSpace.create!(params[:scratch_space])
      create_table_in_scratch_space(scratch_space)
      
      redirect_to :action => 'scratch_space', :id => scratch_space.id
    end
  
    def scratch_space
      ScratchSpace.with_privacy(session[:user_id]) {
        @page_url = "#{request.protocol}#{$profile.hostname}#{request.request_uri}"
        logger.info @page_url
        @scratch_space = ScratchSpace.find(params[:id])
        @creator = @scratch_space.person
        # @last_edit = @procedure.changes[-1]
        # @tagcloud = makeTagcloud([@procedure])
      }
    rescue ActiveRecord::RecordNotFound => e
      if ScratchSpace.exists?(params[:id])
        render :action => "notauthorized"
      else
        render :action => "noexist"
      end
    end

    def mark_scratch_space_private
      ScratchSpace.with_privacy(session[:user_id]) {
        priv = params[:p]
        @scratch_space = ScratchSpace.find(params[:id])
        if priv == "1"
          @scratch_space.private = true
          @scratch_space.save!
          render :update do |page|
            page["private_span"].innerHTML = "Scratch space is now private"
            page["proc_header"].removeClassName("proc_header")
            page["proc_header"].addClassName("proc_header_private")
          end
        else
          @scratch_space.private = false
          @scratch_space.save!
          render :update do |page|
            page["private_span"].innerHTML = "Scratch space is now public"
            page["proc_header"].removeClassName("proc_header_private")
            page["proc_header"].addClassName("proc_header")
          end
        end
      }
      rescue Exception => e
        render :update do |page|
          page["private_span"].innerHTML = "Error: #{e}"
        end
    end

    # ----------------------------------------------------------------------
    # display profile of a person
    def profile
        logger.info("In profile, id is #{params[:id]}")
        if params[:id].nil?
            # sometimes you can get here when you log out from a person page
            # because it will redirect to 'person' with no params[:id]
            redirect_to :action => 'people'
            return
        end

        @person = Person.find_by_shortname(params[:id])
    
        if @person.nil?
            @person = Person.new
            @person.name = params[:id]
            # don't save it!  Just create the record for page display purposes
        end
    end

    def edit_profile
        # Set @person to the person identified by params[:id] only if
        # that person matches the person logged in.
        @person = nil
        potential_person = Person.find_by_shortname(params[:id])
        if potential_person and session[:user_id] == potential_person.id
            @person = potential_person
        end
    end

    def update_profile
        # Set @person to the person identified by params[:id] only if
        # that person matches the person logged in.
        person_to_update = Person.find_by_shortname(params[:id])
        if person_to_update and session[:user_id] == person_to_update.id
            originalHomePageUrl = params[:person][:home_page_url].strip
            if (not originalHomePageUrl.empty?) and (originalHomePageUrl.index("http://") != 0)
                params[:person][:home_page_url] = "http://" + originalHomePageUrl
            end
            person_to_update.update_attributes(params[:person])
            redirect_to :action => "profile", :id => params[:id]
        else
            render :action => "notauthorized"
        end
    end

    # ----------------------------------------------------------------------
    # display a single procedure
    def script
        Procedure.with_privacy(session[:user_id]) {
            @page_url = "#{request.protocol}#{$profile.hostname}#{request.request_uri}"
              logger.info @page_url
            @procedure = Procedure.find(params[:id],:include=>:tags)
            @creator = @procedure.person
            @last_edit = @procedure.changes[-1]
            @related = Procedure.find_approximate(@procedure.salient_words).
                delete_if { |p| p.id == @procedure.id }[0..4]
            @tagcloud = makeTagcloud([@procedure])
            @me = logged_in_user
            if @me.nil?
                @is_favorite = false
            else
                @is_favorite = @me.favorite_scripts.exists?(@procedure)
            end
        }
    rescue ActiveRecord::RecordNotFound => e
        if Procedure.exists?(params[:id])
            render :action => "notauthorized"
        else
            render :action => "noexist"
        end
    end
    def procedure
      redirect_to :action => 'script', :id => params[:id]
    end

    # Show a form that lets users edit the specified procedure
    def edit
        Procedure.with_privacy(session[:user_id]) {
            @procedure = Procedure.find(params[:id])
        }
    end

    # Do the work to update the database
    def update
        Procedure.with_privacy(session[:user_id]) {
            procedure = Procedure.find(params[:id])
            oldtitle = procedure.title
            if updateProcedure(params[:id], params[:procedure])
                procedure.reload()
                creator = logged_in_user()
                # Send an email if necessary
                if procedure.person != creator and $profile.send_email?
                    send_email_about_script_modification(
                        creator, procedure, params[:changelog], oldtitle)
                end

                flash[:notice] = 'Script was successfully updated.'
                    redirect_to :action => 'script', :id => params[:id]
            else
                render :action => 'edit'
            end
        }
    end

    # Action when user presses delete button on a procedure
    def delete
        Procedure.with_privacy(session[:user_id]) {
            if not request.post?
                flash[:notice] = 'You must use a POST request to delete scripts'
                redirect_to :action => 'script', :id => params[:id]
            else
                # make sure they have the right to do this
                current_user = (session[:user_id] == nil) ? nil : Person.find(session[:user_id])
                p = Procedure.find(params[:id])
                if p.person == current_user or not current_user.administrator.nil?
                    # update changelog
                    change = createChangelog(p, current_user, true, nil, 'SCRIPT DELETED')
                    change.save

                    Procedure.destroy(params[:id])
                    flash[:notice] = 'Script successfully deleted'
                    redirect_to :action => 'index'
                else
                    flash[:notice] = 'You do not have permission to delete this script'
                    redirect_to :action => 'script', :id => params[:id]
                end
            end
        }
    end

    # create a new script
    def new
        Procedure.with_privacy(session[:user_id]) {
            if request.get?
                @procedure = Procedure.new
                if not params[:title].nil?
                    @procedure.title = params[:title]
                end
                if not params[:body].nil?
                    @procedure.body = params[:body]
                end
            else
                if createProcedure(params[:procedure])
                    flash[:notice] = 'Script was successfully created.'
                    redirect_to :action => 'script', :id => @procedure
                end
            end
        }
    end

    # make a copy of an existing script
    def copy
        Procedure.with_privacy(session[:user_id]) {
            if request.get?
                @procedure = Procedure.find(params[:id])
                @procedure.title = 'Copy of ' + @procedure.title
                @copyid = @procedure.id
            else
                # POST; actually create the script
                @procedure = Procedure.new
                @procedure.modified_at = Time.now.utc
                @procedure.created_at = Time.now.utc
                @procedure.person = Person.find(session[:user_id])
                if @procedure.update_attributes(params[:procedure])
                    flash[:notice] = 'Script was successfully created.'
                    redirect_to :action => 'script', :id => @procedure
                end

                # make a changelog
                change = createChangelog(@procedure, @procedure.person, false,
                    params[:changelog], "COPY OF SCRIPT #{params[:copyid]}")
                change.save
            end
        }
    end

    # implement search
    def search
      Procedure.with_privacy(session[:user_id]) {
    @query = params['q']
    logger.info("Search query: <#{@query}>")
    if @query.nil? or @query.strip == ""
        logger.info("Search query: <#{@query}>")
        @procedures = @people = []
    else
            @procedures = Procedure.find_all_by_title(@query)
        @procedures = @procedures | Procedure.find_approximate(@query)
        logger.info("Found #{@procedures.length} direct matches")
        @comments = ProcedureComment.find_by_text(@query)
        @comments.reject! { |c| c.procedure.nil?  }
        logger.info("Found #{@comments.length} matching comments")
        @procedures = @procedures | @comments.map {|comment| comment.procedure}
        @procedures = @procedures | Tag.find_by_keyword(@query)
        @people = Person.search_by_term(@query)
    end
    person_procedures = @people.map {|person| person.procedures}
    person_procedures.flatten!
    @procedures = @procedures.delete_if {|p| p.nil?}

    # pagination
    items_per_page = 20
    if params[:page] == 'all' 
      items_per_page = @procedures.length unless @procedures.length < 1 
    else
      page = params[:page].to_i unless params[:page].to_i == 0
    end
    @procedures = @procedures.paginate(:per_page =>items_per_page,:page=> page)
    @tagcloud = makeTagcloud(@procedures + person_procedures)
      }
    end

    # an about page
    def about
      Procedure.with_privacy(session[:user_id]) {
    @bestbets = BestBet.find_all_procedures
      }
    end

    def stars
      Procedure.with_privacy(session[:user_id]) {
    @procedure = Procedure.find(params[:id])
    render :layout => false
      }
    end

    def scripthistory
      require 'rubygems'
      require 'google_chart'
      @me = logged_in_user

      person_id = session[person_id]
      procedure = Procedure.find(params[:id])
      pes = procedure.procedure_executes
      dates = []
      mydates = [] 
      xmax = 0 
      ymax = 0 
      pes.each{|pe| 
    days = ((pe.executed_at - procedure.created_at )/(60*60*24)).to_i 
    if days > xmax 
      xmax = days
    end
    if not @me.nil?
      if pe.person_id == @me.id
        if mydates[days].nil?
          mydates[days] = 1 
        else 
          mydates[days] = mydates[days] + 1 
        end
      end
    end
    if dates[days].nil?
      dates[days] = 1 
    else 
      dates[days] = dates[days] + 1 
    end
      }

      (0..xmax).each{|i|
    if dates[i].nil?
      dates[i] = 0
    end
    if mydates[i].nil?
      mydates[i] = 0
    end
    if dates[i] > ymax 
      ymax = dates[i]
    end
      }  
      logger.warn("ymax is now #{ymax}")
      lc = GoogleChart::LineChart.new("#{xmax}x150", "Script History", false)
      lc.data "Total", dates, '7777ff'
      lc.data "You", mydates, 'ff7777' unless @me.nil?
      lc.line_style 0, :length_segment => 3, :length_blank => 2
      lc.line_style 1, :length_segment => 1, :length_blank => 2
      lc.axis :x, :range => [0,xmax],:color =>'222222',:font_size => 10, :alignment => :center, :labels => ['creation']
      lc.axis :y, :range => [0,ymax]
      lc.grid :y_step => 10
      @img_url = lc.to_url
    end

    # send via email
  def share
    begin
      Procedure.with_privacy(session[:user_id]) {
        @me = Person.find(session[:user_id])
        @procedure = Procedure.find(params[:id])
        @subject = 'Script share: ' + @procedure.title
        @sender_name = @me.name
        @procurl = url_for(:controller => 'browse',
        :action => 'script', :id => @procedure)
        @body = render_to_string(:partial => 'mailer/share')
        
        if not request.get?
          recipients = params['recipient_email']
          if recipients.strip == ""
            flash[:notice] = 'No recipients specified'
            return
          end
          params['sender'] = @me.name + ' <' +\
          @me.email + '>'
          email = Mailer.deliver_share(params)
          flash[:notice] = "Mail sent to \"#{recipients}\""
          redirect_to :action => 'script', :id => @procedure
        end
      }
      rescue 
        flash[:notice] = 'Our authentication service is experiencing problems. Please try again in a couple of minutes. Sorry for the inconvenience.'
        redirect_to :controller=>:browse,:action=>:about
      end
    end

    def add_comment
        Procedure.with_privacy(session[:user_id]) {
            @procedure = Procedure.find(params[:id])
            @comment = ProcedureComment.new
            @comment.person = Person.find(session[:user_id])
            @comment.comment = params['comment']
            @comment.procedure = @procedure
            @comment.save

            # send via email only if we're on the intranet
            if $profile.send_email?
                @sender_name = @comment.person.name
                if @comment.person != @procedure.person
                    # only send email if the person making the comment is
                    # not the person owning the script
                    comment_details = {
                        'recipients' => [@procedure.person.email],
                        'sender' => $profile.site_email,
                        'subject' => "Comment about \"#{@procedure.title}\"",
                        'body' => render_to_string(:partial => 'mailer/comment')
                    }
                    Mailer.deliver_comment(comment_details)

                    recipients = [@procedure.person.name]

                    comments = @procedure.procedure_comments.sort { |x, y| x.updated_at <=> y.updated_at }
                    other_commenters = comments.collect { |c| c.person }
                    other_commenters = other_commenters.delete_if { |p| p.nil? }
                    other_commenters = other_commenters.uniq
                    # delete the person who wrote the comment
                    other_commenters.delete(@comment.person)
                    # delete the script author
                    other_commenters.delete(@procedure.person)
                    recipients += other_commenters.collect { |p| p.name }
                    other_commenters = other_commenters.collect { |p| p.email }

                    for commenter in other_commenters
                        comment_details = {
                            'recipients' => [commenter],
                            'sender' => $profile.site_email,
                            'subject' => "Comment about \"#{@procedure.title}\"",
                            'body' => render_to_string(:partial => 'mailer/comment')
                        }
                        Mailer.deliver_comment(comment_details)
                    end

                    if recipients.length == 1
                        names = recipients[0]
                    elsif recipients.length == 2
                        names = "#{recipients[0]} and #{recipients[1]}"
                    elsif recipients.length > 2
                        names = "#{recipients[0..-2].join(', ')}, and #{recipients[-1]}"
                    end
                    flash[:notice] = "Comment emailed to #{names}"
                else
                    flash[:notice] = "Your comment was added"
                end
            else
                flash[:notice] = "Your comment was added"
            end

            redirect_to :action => 'script', :id => @procedure
        }
    end

    def delete_comment
        Procedure.with_privacy(session[:user_id]) {
            comment = ProcedureComment.find(params[:id])
            if logged_in_user() != comment.person
                render :text => "You do not own this comment"
                return
            end
            comment.destroy
            render :text => ""
        }
    end

    # ----------------------------------------------------------------------
    # show tags

    # Tags
    def tag
        Procedure.with_privacy(session[:user_id]) {
            @tag = params[:id]
            if @tag.nil?
                @procedures = []
            else
                @tags = Tag.find_all_by_clean_name(@tag)
                @procedures = @tags.map {|tag| tag.procedure}
                # filter out dups
                @procedures = @procedures & @procedures
                @procedures = @procedures.delete_if {|p| p.nil?}
            end

            @tagcloud = makeTagcloud(@procedures)
        }
    end

    def add_tags
      Procedure.with_privacy(session[:user_id]) {
        @procedure = Procedure.find(params[:id])
        add_tags_to_procedure(@procedure, params[:raw_tags])
        @tagcloud = makeTagcloud([@procedure])
        render :update do |page|
            page.replace_html("mytags_panel", :partial => "mytags", :object => @procedure.tags)
            page.replace_html("tagcloud_panel",
                :partial => "tagcloud",
                :locals => {:useNumPersonHeader => true} )
        end
      }
    end
    
    def delete_tag
      Procedure.with_privacy(session[:user_id]) {
    tag = Tag.find(params[:id])
    @procedure = tag.procedure
    tag.destroy
    @tagcloud = makeTagcloud([@procedure])
    render :update do |page|
        page.replace_html("mytags_panel", :partial => "mytags", :object => @procedure.tags)
            page.replace_html("tagcloud_panel",
                :partial => "tagcloud",
                :locals => {:useNumPersonHeader => true} )
    end 
      }
    end
    

    # ----------------------------------------------------------------------
    # Private scripts
    def mark_private
        Procedure.with_privacy(session[:user_id]) {
            priv = params[:p]
            @procedure = Procedure.find(params[:id])
            if priv == "1"
                @procedure.private = true
                @procedure.save!
                render :update do |page|
                    page.call 'location.reload'
                    flash[:notice] = "This script is now private"
                end
            else
                @procedure.private = false
                @procedure.save!
                render :update do |page|
                    page.call 'location.reload'
                    flash[:notice] = "This script is now public"
                end
            end
        }
    rescue Exception => e
        render :update do |page|
            page["private_span"].innerHTML = "Error: #{e}"
        end
    end
    
    # ----------------------------------------------------------------------
    # Favorite scripts (the star)

    def set_favorite
        @procedure = Procedure.find(params[:id])
        person = logged_in_user()
        unless person.favorite_scripts.include?(@procedure)
            person.favorite_scripts << @procedure
            person.save!
        end
        render :partial => "star", :layout => false, :locals => {
            :me => person, :procedure => @procedure, :is_favorite => true }
    end

    def unset_favorite
        @procedure = Procedure.find(params[:id])
        person = logged_in_user()
        if person.favorite_scripts.include?(@procedure)
            person.favorite_scripts.delete(@procedure)
        end
        render :partial => "star", :layout => false, :locals => {
            :me => person, :procedure => @procedure, :is_favorite => false }
    end

    # ----------------------------------------------------------------------
    # Changelog / page history / versions
    def versions
      Procedure.with_privacy(session[:user_id]) {
    @procedure = Procedure.find(params[:id])
        @sorted_changes = @procedure.changes.sort {
          |x, y| y.modified_at <=> x.modified_at }
      }
    rescue ActiveRecord::RecordNotFound => e
      if Procedure.exists?(params[:id])
    render :action => "notauthorized"
      else
    render :action => "noexist"
      end
    end

    def version
        # yuck ... there should be a better way to respect privacy than this
        private_cond = "procedures.private = false"
        if session[:user_id]
            private_cond += " or procedures.person_id = ?"
            cond = [private_cond, session[:user_id]]
        else
            cond = [private_cond]
        end
        change = Change.find(params[:id],
            :joins => "join procedures on procedures.id = changes.procedure_id",
            :select => "changes.*",
            :conditions => cond)
        render :text => RedCloth.new(change.body).to_html
    rescue ActiveRecord::RecordNotFound => e
        if Change.exists?(params[:id])
            render :text => "You are not authorized to view this version"
        else
            render :text => "The requested version does not exist"
        end
    rescue Exception => e
        render :text => "Error retrieving version: #{e}"
    end

    def diff
        Procedure.with_privacy(session[:user_id]) {
            c = Change.find(params[:id])
            p = c.procedure
            if p.nil?
                render :text => "Either the requested version does not exist, or you are not authorized to view it"
                return
            end

            index = p.changes.index(c)
            if index == 0
                render :text => "No previous change to diff with"
                return
            elsif index == -1
                render :text => "Error locating this change"
                return
            end

            lastchange = p.changes[index - 1]

            diff = getdiff(lastchange.body.split(/\r?\n/),
                c.body.split(/\r?\n/))
            render :partial => 'diff', :object => diff
        }
    rescue ActiveRecord::RecordNotFound => e
        if Change.exists?(params[:id])
            render :text => "You are not authorized to view this version"
        else
            render :text => "The requested version does not exist"
        end
    rescue Exception => e
        render :text => "Error retrieving version: #{e}"
    end

    def revert
      Procedure.with_privacy(session[:user_id]) {
        change = Change.find(params[:id])
        if (change.procedure.nil?)
          render :action => "notauthorized"
          return
        end
        @procedure = change.procedure
        @procedure.title = change.title
        @procedure.body = change.body
        render :template => "browse/edit"
      }
    rescue ActiveRecord::RecordNotFound => e
      render :action => "noexist"
    end

    # ----------------------------------------------------------------------
    # Requests for help with a specific site
    
    def wish
        if params[:id].nil?
            redirect_to :action => "wishlist"
        else
            @wish = Wish.find(params[:id])
        end
    rescue ActiveRecord::RecordNotFound => e
        render :action => "noexist_wish"
    end

    def wishlist
      @logged_in_user = logged_in_user()
      if not params[:id].nil?
        # limit to a certain person's requests
        @person = Person.find_by_shortname(params[:id])
        if @person.nil?
          @wishes = []
        else
          @wishes = @person.wishes.paginate(:page=>params[:page])
        end
      else
        @person = nil
        @wishes = Wish.paginate(
                :order => "created_at desc", :page=>params[:page])
      end

    end

    def delete_wish_remote
        wish = Wish.find(params[:id])
        if logged_in_user() != wish.person
            render :text => "You do not own this wish"
            return
        end

        wish.destroy
        render :text => ""
    rescue Exception => e
        render :text => "Error deleting wish: #{e}"
    end

    def delete_wish
        wish = Wish.find(params[:id])
        if logged_in_user() != wish.person
            render :text => "You do not own this wish"
            return
        end

        wish.destroy
        redirect_to :action => :wishlist, :id => logged_in_user().profile_id
    rescue Exception => e
        render :text => "Error deleting wish: #{e}"
    end

    def add_wish_comment
        @wish = Wish.find(params[:id])
        @comment = WishComment.new
        @comment.person = logged_in_user()
        @comment.comment = params['comment']
        @comment.wish = @wish
        @comment.save

        # send via email only if we're on the intranet
        if $profile.send_email?
            @sender_name = @comment.person.name
            if @comment.person != @wish.person
                # only send email if the person making the comment is
                # not the person owning the script
                comment_details = {
                    'recipients' => [@wish.person.email],
                    'sender' => @comment.person.name + ' <' +\
                        @comment.person.email + '>',
                    'subject' => "Comment about your wish on \"#{@wish.title}\"",
                    'body' => render_to_string(:partial => 'mailer/wishcomment')
                }
                Mailer.deliver_comment(comment_details)
                flash[:notice] = "Comment emailed to #{@wish.person.name} &lt;#{@wish.person.email}&gt;"
            else
                flash[:notice] = "Your comment was added"
            end
        else
            flash[:notice] = "Your comment was added"
        end

        redirect_to :action => 'wish', :id => @wish
    end

    def delete_wish_comment
        comment = WishComment.find(params[:id])
        if logged_in_user() != comment.person
            render :text => "You do not own this wish comment"
            return
        end
        comment.destroy
        render :text => ""
    end

    # ----------------------------------------------------------------------
    # Access control
    def acl_add
        Procedure.with_privacy(session[:user_id]) {
            @procedure = Procedure.find(params[:id])
            new_person = Person.find_by_shortname(params[:user])
            if new_person.nil?
                render :update do |page|
                    page.replace_html("acl_status", "#{params[:user]} is not a CoScripter user")
                end
                return
            else
                if not @procedure.members.include? new_person
                    @procedure.members << new_person
                end
                render :update do |page|
                    page.replace_html("acl_box", :partial => "acl",
                        :object => @procedure)
                end
                return
            end
        }
    rescue Exception => e
        render :update do |page|
          page.replace_html("acl_status", "Error: #{e}")
        end
    end

    def acl_del
        Procedure.with_privacy(session[:user_id]) {
            @procedure = Procedure.find(params[:id])
            new_person = Person.find_by_shortname(params[:user])
            if new_person.nil?
                render :update do |page|
                    page.replace_html("acl_status", "Person not found")
                end
                return
            end

            if not @procedure.members.include? new_person
                render :update do |page|
                    page.replace_html("acl_status", "Error: person not in ACL")
                end
                return
            end

            @procedure.members.delete(new_person)
            render :update do |page|
                page.replace_html("acl_box", :partial => "acl",
                    :object => @procedure)
            end
        }
    rescue Exception => e
        render :update do |page|
          page.replace_html("acl_status", "Error: #{e}")
        end
    end
    def  auto_complete_for_people_name
      @people= Person.find(:all, :conditions=>["LOWER(name) LIKE ?","%#{params[:user].downcase}%"])
      render :inline => "<%= auto_complete_result @people, 'name' %>"
    end
    # ----------------------------------------------------------------------
    # TOS agreement
    def tos
    end

end
