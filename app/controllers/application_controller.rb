# (C) Copyright IBM Corp. 2010
# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
require 'json'

class ApplicationController < ActionController::Base
    # Set up support for emailing notifications to people when something
    # fails in the application.
    include ExceptionNotifiable
    filter_parameter_logging "w3pass", "password"

    # Provides a consistent date/time for this request, so that
    # multiple methods who need a request time can get the same
    # time. Set by the log_site_access before filter.
    attr_reader :http_request_datetime
    
    # tell the browser that we send pages in utf-8 encoding
    after_filter :set_charset

    before_filter :log_site_access, :avoid_blacklisted_ips
    
#    before_filter :require_https, :only => [:login,:register] 
#    before_filter :require_http, :except => [:login,:register] 

    def require_https 
      redirect_to(url_for(params.merge({:protocol => "https://"}))) unless (request.ssl? or request.post? or local_request? )
    end 
    #todo: implement our own local_request to check for X_FORWARDED_FOR or something so proxying will check for the rigt "local_request"
  #   def local_request?
  # 
  #   end

    def require_http
      redirect_to(url_for(params.merge({:protocol => "http://"}))) if (request.ssl?) 
    end
     # ----------------------------------------------------------------------
    # Authorization

    # this also appears in app/helpers/application_helper.rb -- where should
    # it go?
    def is_logged_in?
      return (not session[:user_id].nil?)
    end

    # Authorize a user using a login form
    def authorize_session
        if session[:user_id].nil?
            redirect = request.env['REQUEST_URI']
            redirect_to :action => 'login', :controller => 'login',
                :redirect => redirect
            return false
        else
            if Person.find_by_id(session[:user_id]).nil?
                session[:user_id] = nil
            end
        end
    end

    def authorize_session_lite
        if session[:user_id].nil?
                redirect = request.env['REQUEST_URI']
            redirect_to :action => 'login', :controller => 'lite',
                :redirect => redirect
            return false
        end
    end

    # Authorize using basic authentication
    def authorize_iip
        username, passwd = get_auth_data
        if Person.authenticate(username, passwd)
            user = Person.find_by_email(username)
            if user.nil?
                user = Person.new_by_email(username)
            end
            session[:user_id] = user.id
        else
            return_unauthorized
        end
    end

    # Authorize using either session or iip
    def authorize_session_or_iip
    if not session[:user_id].nil?
        authorize_session
    else
        authorize_iip
    end
    end

    def require_admin
        logger.warn("Requiring admin access")
        current_user = (session[:user_id] == nil) ? nil :
            Person.find(session[:user_id])
        if current_user.nil? or current_user.administrator.nil? 
            render :text =>
                "You need administrator privileges to use this function",
                :status => 403
            return false
        end
    end

    # ----------------------------------------------------------------------
    # Common code for updating procedures used by different views
    #
    def updateProcedure(procid, procparams)
        @procedure = Procedure.find(procid)
        @procedure.modified_at = Time.now.utc
        @procedure.update_attributes(procparams)
        # update changelog
        change = createChangelog(@procedure, Person.find(session[:user_id]))
        change.save!
    end

    def createProcedure(procparams)
        person = Person.find(session[:user_id])
        @procedure = Procedure.new
        @procedure.modified_at = Time.now.utc
        @procedure.created_at = Time.now.utc
        @procedure.person = person
        @procedure.update_attributes(procparams)
        # update changelog
        change = createChangelog(@procedure, person, false, '', 'NEW SCRIPT')
        change.save!
    end

    def createChangelog(procedure, person, deleted = false, changelog = nil,
        syslog = nil)
        logger.warn("Creating changelog, value: #{changelog}")
        change = Change.new
        change.procedure_id = procedure.id
        change.person = person
        if deleted
            change.body = 'DELETED'
        else
            change.body = procedure.body
        end
        if not changelog.nil?
            change.log = changelog
        end
        if not syslog.nil?
            change.syslog = syslog
        end
        change.title = procedure.title
        change.modified_at = procedure.modified_at
        return change
    end

    # ----------------------------------------------------------------------
    # effect is to set session[:user_id]
    # make sure authenticate is ca (TL: wha?)
    def loginUser(email, displayname=nil)
      if not email.nil? and not email.empty? 
        user = Person.find_by_email(email)
        if not user.nil?
          session[:user_id] = user.id
          return true
        end 
      end 
      return false
    end


  
    # ----------------------------------------------------------------------
    # check is user has been logged in before
    #
    def firsttimeUser(email)
        profileId = $profile.profile_id_for_email(email)
        user = Person.find_by_profile_id(profileId)
        user.nil?
    end
    # ----------------------------------------------------------------------
    # for debugging -- enable angst as local host so I can see debug
    # messages on the production server
    def local_request?
        ['127.0.0.1'].include?(request.remote_ip)
    end

    # ----------------------------------------------------------------------
    # Helper functions

    def send_json(out, cb=nil, status="200")
      begin
    ret = out.to_json
    unless cb.nil?
      ret = "#{cb}(#{ret})"
    end
    send_data(ret, :type => 'application/x-javascript',
          :disposition => 'inline', :status => status)
      rescue Exception => e
    puts("*** Exception in send_json: #{e} \n#{e.backtrace.join('\n')}***")
      end
    end

    # TODO: work around lack of Unicode handling by setting all pages
    # as utf-8 encoding.  This is only an incomplete fix.
    def set_charset
      content_type = headers["Content-Type"] || 'text/html'
      if /^text\//.match(content_type)
        headers["Content-Type"] = "#{content_type}; charset=utf-8" 
      end
    end

    def log_site_access
        @http_request_datetime = Time.now.utc

        person = nil
        if not session[:user_id].nil?
            begin
            person = Person.find(session[:user_id])
	    person.last_active_at = @http_request_datetime unless person.nil?
	    person.save
            rescue Exception => e
              session[:user_id] = nil
            end
	end
	client_version = request.env["HTTP_COSCRIPTERVERSION"]
	SiteUsageLog.create(
            :accessed_at => @http_request_datetime,
            :controller => controller_name,
            :action => action_name,
            :uri => request.request_uri,
            :coscripter_session_id => cookies[:coscripter_session_id],
            :person => person,
            :ip => request.remote_ip,
        :referrer => request.referer,
        :client_version => client_version
        )

    end

  def avoid_blacklisted_ips
    ip = request.remote_ip.split(':')[-1]
    bl = Blacklist.find_by_ip_address(ip)

    unless bl.nil?
      @ip = ip 
      render :file=>"#{RAILS_ROOT}/public/406.html",:layout =>false, :status=>406
    end
  end

    def send_email_about_script_modification(creator, procedure, log, oldtitle)
        @creator = creator
        @procedure = procedure
        @changelog = log
        @diff 

        changes = Change.find(:all,
            :conditions => ["procedure_id = ?", @procedure.id],
            :order => "modified_at desc",
            :limit => 2)
        if changes.length == 1
            # only one change; send the body of the script
            scriptdiff = render_to_string :partial => "shared/script",
                :object => changes[0].body
        else
            diff = getdiff(changes[1].body.split(/\r?\n/),
                changes[0].body.split(/\r?\n/))
            scriptdiff = render_to_string :partial => "shared/scriptdiff",
                :object => diff
        end

        @whichscript = "one of your scripts"
        mail_details = {
            'recipients' => [@procedure.person.email],
            'sender' => "CoScripter <#{$profile.site_email}>",
            'subject' =>
                "\"#{oldtitle}\" has been modified",
            'body' => render_to_string(:partial => "mailer/script_modified",
                :object => scriptdiff)
        }
        Mailer.deliver_script_modified(mail_details)

        # now check for people who have modified the script and would also
        # be interested
        people = @procedure.changes.collect { |ch| ch.person }
        people = people.delete_if { |p| p.nil? }
        emails = people.collect { |p| p.email }
        emails = emails.uniq
        # delete the script creator because they were already notified
        emails.delete(@procedure.person.email)
        # the person who just made the change also doesn't need to know
        emails.delete(@creator.email)
        emails.delete_if { |p| p.nil? }
        for email in emails
            @whichscript = "a script you have contributed to"
            mail_details = {
                'recipients' => [email],
                'sender' => "CoScripter <#{$profile.site_email}>",
                'subject' =>
                    "\"#{oldtitle}\" has been modified",
                'body' => render_to_string(:partial => "mailer/script_modified",
                    :object => scriptdiff)
            }
            Mailer.deliver_script_modified(mail_details)
        end
        
    rescue Exception => e
        logger.error("Error generating script modification email: #{e}")
    end
    
    private
    def return_unauthorized(msg=nil)
        if msg.nil?
            msg = "Unable to authenticate using your #{$profile.id_name} and password\n"
        end
        response.headers['WWW-Authenticate'] =
            "Basic realm=\"#{$profile.id_name}\""
        render :text => msg, :status => 401
    end

    # TODO: support digest authentication?
    private
    def get_auth_data
        user, pass = '', ''
        # extract auth credentials
        if request.env.has_key? 'X-HTTP_AUTHORIZATION' 
            # try to get it where mod_rewrite might have put it 
            authdata = request.env['X-HTTP_AUTHORIZATION'].to_s.split 
        elsif request.env.has_key? 'Authorization' 
            # for Apace/mod_fastcgi with -pass-header Authorization 
            authdata = request.env['Authorization'].to_s.split 
        elsif request.env.has_key? 'HTTP_AUTHORIZATION' 
            # this is the regular location 
            authdata = request.env['HTTP_AUTHORIZATION'].to_s.split  
        elsif request.env.has_key? 'Authorization'
            # this is the regular location, for Apache 2
            authdata = @request.env['Authorization'].to_s.split
        end 

        # at the moment we only support basic authentication 
        if authdata and authdata[0] == 'Basic' 
            user, pass = Base64.decode64(authdata[1]).split(':')[0..1] 
        end 
        return [user, pass] 
    end

    # ----------------------------------------------------------------------
    # Utility functions

    # returns
    # {:tags =>
    #    a list of [tag name, {:size => relative size, :people => Set of people}],
    #  :people => a Set of people who created those tags}
    # 
    # The relative size of the tag will always be an integer from 1..scale
    private
    def makeTagcloud(proclist, scale = 4, limit = -1)
        if proclist.length == 0
          return {}
        end

    taglist = {}
    proclist.each { |p|
        tags = p.tags
        tags.each { |tag|
        if taglist[tag.clean_name].nil?
            taglist[tag.clean_name] = []
        end
        taglist[tag.clean_name].push(tag)
        }
    }
        sorted_tags = taglist.sort { |x, y| y[1].length <=> x[1].length }
        if limit != -1
          sorted_tags = sorted_tags[0..limit-1]
        end
        if sorted_tags.length == 0
          return {}
        end
#        logger.warn("#{sorted_tags.length} sorted tags: #{sorted_tags}")

        values = sorted_tags.collect { |x| x[1].length }
    max = values.max
    min = values.min
        range = max - min + 1

        scaled_sorted_tags = {}
        taggers = Set.new
        
    sorted_tags.each {|tag_name, tags|
      scaled_sorted_tags[tag_name] = {}
          if range == 1
            scaled_sorted_tags[tag_name][:size] = scale / 2
          else
            scaled_sorted_tags[tag_name][:size] = ((tags.length - min) / (1.0*range / scale)).to_i
          end
          scaled_sorted_tags[tag_name][:people] = Set.new
          tags.each {|tag|
            taggers.add(tag.person)
            scaled_sorted_tags[tag_name][:people].add(tag.person)
          }
    }
#        logger.warn("Returning sorted tag cloud: #{scaled_sorted_tags.sort}")
        
    {:tags => scaled_sorted_tags.sort {|a, b| a[0] <=> b[0]},
     :people => taggers}
    end

    # ----------------------------------------------------------------------
    # Recently touched scripts
    class ProcedureWithEvent
      def initialize(procedure, event)
        @procedure = procedure 
        @event = event
      end
      def procedure
        return @procedure
      end
      def event 
        return @event
      end
      # necessary method so uniq on array of PWE's will make sure every 
      # procedure is only contained once
      def hash
        return @procedure.hash
      end
      def eql?(pwe2)
        return @procedure.eql?(pwe2.procedure)
      end
      def effective_date
        if @event.instance_of?(Procedure)
          return @event.modified_at
        elsif @event.instance_of?(ProcedureExecute)
          return @event.executed_at
        elsif @event.instance_of?(Change)
          return @event.modified_at
        else
          return nil
        end
      end
    end

    # since is a timestamp in seconds since the epoch
    # returns a list of ProcedureWithEvent objects
    def procedures_recently_touched(person, max = 20, since = nil)
        Procedure.with_privacy(person.id) {
            if not since.nil?
              conditions = ['modified_at > ?', since]
            else
              conditions = []
            end
            events = Procedure.find_all_by_person_id(person.id,
              :limit => max,
              :order => 'modified_at desc', :conditions => conditions)
            if not since.nil?
              conditions = ['executed_at > ?', since]
            else
              conditions = []
            end
            events += ProcedureExecute.find_all_by_person_id(person.id,
              :limit => max,
              :order => 'executed_at desc',
              :joins => 'inner join procedures on procedures.id = procedure_executes.procedure_id',
              :include => :procedure,
              :conditions => conditions)
            if not since.nil?
              conditions = ['changes.modified_at > ?', since]
            end
            events += Change.find_all_by_person_id(person.id,
              :limit => max,
              :order => 'changes.modified_at desc',
              :joins => 'inner join procedures on procedures.id = changes.procedure_id',
              :include => :procedure,
              :conditions => conditions
              )

            def script_for(ev)
              if ev.instance_of?(Procedure)
                return ProcedureWithEvent.new(ev,ev)
              elsif ev.instance_of?(ProcedureExecute)
                return ProcedureWithEvent.new( ev.procedure,ev)
              elsif ev.instance_of?(Change)
                return ProcedureWithEvent.new( ev.procedure, ev)
              else
                return nil
              end
            end

            procs = events.collect { |ev| script_for(ev) }
            procs = procs.delete_if { |p| p.nil? }
            procs.uniq!
            procs = procs.sort { |x, y|
                y.effective_date <=> x.effective_date }
            return procs
        }
    end

    def getSortOrder(sortorder)
      if sortorder.nil?
    sortorder = 'popularity'
      end
      if not ['usage', 'modified', 'created', 'favorite', 'creator', 'popularity' ].include? sortorder
    sortorder = :usage
      end
      return sortorder
    end
    def is_username(name)
        return name.match(/^[a-zA-Z0-9\_\-\.\@ ]+$/)
    end

    # ----------------------------------------------------------------------
    # Helper functions for determining whether user is logged in

    def logged_in?
      return (session[:user_id].nil?) ? false : (
        Person.find(session[:user_id]).nil? ? false : true)
    end

    def logged_in_user
      return (session[:user_id] == nil) ? nil : Person.find(session[:user_id])
    end

    # ----------------------------------------------------------------------
    # Tagging
    def add_tags_to_procedure(procedure, tagstr)
        new_raw_tags = Tag.split_into_raw_tags(tagstr)
        
        new_raw_tags.each { |new_tag_raw_name|
            new_tag_raw_name.sub!(/"/, '')
            new_tag_clean_name = Tag.create_clean_name(new_tag_raw_name)

            tag_exists = false

            # check for duplicate tags
            procedure.tags.each { |a_tag|
               if (a_tag.clean_name == new_tag_clean_name) and (a_tag.person.id == session[:user_id])
                  tag_exists = true
               end
            }

            if not tag_exists
                tag = Tag.create(
                    :procedure => procedure,
                    :person => Person.find(session[:user_id]),
                    :raw_name => new_tag_raw_name,
                    :clean_name => new_tag_clean_name
                )
                procedure.tags << tag
            end
        }
    end
end
