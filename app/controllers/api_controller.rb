# (C) Copyright IBM Corp. 2010

require 'time'

class ApiController < ApplicationController
    before_filter :authorize_session_or_iip, :except => [
        :byurl, :editorspicks, :find_approximate,
        :find_with_step,:whoami,
        :ping, :popular, :postag, :script, :scripts, :usagelog,
        :makeJSONTestcase, :makeJSONProcedureList, :etsfeed, :useractivity
    ]

    before_filter :require_admin, :only => [ :sloplines ]

    # This does not require authorization, in order to let the Facebook
    # app request information about a script to post it to the user's Wall
    def script
        Procedure.with_privacy(session[:user_id]) {
            case request.method
            when :post
                return if authorize_session_or_iip
                p = _savescript_helper(params)
            when :get
                p = Procedure.find(params[:id])
            else
                render(:text => 'Unsupported HTTP method')
                return
            end
            
            out = makeJSONProcedure(p)
            send_json(out, params[:callback])
        }
    rescue ActiveRecord::RecordNotFound => e
        render :text => "Either this script does not exist, or you do not have permission to view it", :status => "404"
    rescue Exception => e
        logger.warn("Error: #{e}\n" + "#{e.backtrace.join("\n")}\n")
        render :text => "Error: #{e}", :status => "500"
    end
    def procedure
        script
    end

    def savescript
        Procedure.with_privacy(session[:user_id]) {
            if request.method != :post
                raise "You must use the POST method with savescript"
            end

            p = _savescript_helper(params)

            out = makeJSONProcedure(p)
            send_json(out, params[:callback])
        }
    rescue Exception => e
        logger.warn("Error: #{e}\n" + "#{e.backtrace.join("\n")}\n")
        render :text => "Error: #{e}", :status => "500"
    end

    # Actually do the work for saving a script
    # Refactored because both /api/script and /api/savescript call this
    # Eventually /api/script should no longer support the POST method; to
    # save a script, /api/savescript should be called instead
    def _savescript_helper(params)
        Procedure.with_privacy(session[:user_id]) {
            is_new = false
            log = nil
            syslog = nil

            if not params[:id].nil?
                p = Procedure.find(params[:id])
            else
                p = Procedure.new
                # set initial creation time
                p.created_at = Time.now.utc
                is_new = true
                syslog = "NEW SCRIPT"
            end
            # save off old title for email
            oldtitle = p.title
            if not params[:title].nil?
                p.title = params[:title]
            end

            if session[:user_id].nil?
              raise "Must be authenticated to create/update a script"
            end
            creator = Person.find(session[:user_id])
            if is_new
                p.person = creator
            end
            # Override default log if provided by client
            if not params[:changelog].nil?
                log = params[:changelog]
            end
            if not params[:body].nil?
                p.body = params[:body]
            end
            if not params[:private].nil?
                privparam = params[:private] == 'true'
                # only the script creator can set the private flag
                if (p.person.id != session[:user_id] and
                  privparam != p.private?)
                  raise "Only script creator can update private flag"
                end
                p.private = params[:private]
            end

            # update modification time
            p.modified_at = Time.now.utc
            p.save!

            # set up the tags
            if not params[:tags].nil?
                add_tags_to_procedure(p, params[:tags])
            end

            # Always create a changelog, even on the first save
            change = createChangelog(p, creator, false, log, syslog)
            change.save!

            # Send an email if necessary
            if p.person != creator and $profile.send_email?
                # only send email if the person making the change is
                # not the person owning the script
                # TODO: check p.person's opt-out setting
                send_email_about_script_modification(
                    creator, p, log, oldtitle)
            end

            return p
        }
    end

  # ----------------------------------------------------------------------
  # Scratch spaces
  # ----------------------------------------------------------------------
  def get_ids_from_scratch_space(space)
    id_data = {"id" => space.id, "tableIds" => []}
    space.scratch_space_tables.each do |table|
      id_data["tableIds"] << table.id
    end
    return id_data
  end

  # TL: It looks like this this is not designed to be called as an API
  # call; it should be a private method instead
  def get_scratch_space_from_params()
    if not params[:id].nil?
      space = ScratchSpace.find(params[:id])
    else
      space = ScratchSpace.new
    end
    
    creator = Person.find(session[:user_id])

    if not params[:title].nil?
      space.title = params[:title]
    else
      space.title = "Untitled"
    end

    if not params[:description].nil?
      space.description = params[:description]
    else
      space.description = ""
    end

    space.person = creator

    if not params[:spaceIsPrivate].nil?
      space.private = params[:spaceIsPrivate]
    else
      space.private = true
    end

    tables_data = JSON.parse(params[:tablesJson])
    tables_data.each do |table_data|
      if not table_data['id'].nil?
        table = ScratchSpaceTable.find(table_data['id'])
        new_table = false
      else
        table = ScratchSpaceTable.new
        new_table = true
      end
      table.title = table_data['title']
      table.data_json = table_data['dataJson']
      table.notes = table_data['notes']
      table_data['scriptIds'].each do |script_id|
        script_with_id = Procedure.find(script_id)
        if not table.procedures.include?(script_with_id)
          table.procedures << script_with_id
        end
      end
      table.log = table_data['log']
      
      if new_table
        table.scratch_space = space
      end
      
      table.save!
    end
    
    space.save!
    return space
  end


  def scratch_spaces
    ScratchSpace.with_privacy(session[:user_id]) {
      case request.method
      when :post
        # create a new scratch space
        if session[:user_id].nil?
          raise "Must be authenticated to create/update a scratch space"
        end

        new_space = get_scratch_space_from_params()

        # TODO log changes
        
        send_json(get_ids_from_scratch_space(new_space))
      when :get
        spaces = ScratchSpace.find(:all)
        spaces_data = []
        spaces.each do |space|
          spaces_data << {
            'id' => space.id, 
            'title' => space.title, 
            'description' => space.description
          }
        end
        
        send_json(spaces_data)
      else
        render(:text => 'Unsupported HTTP method')
        return
      end
    }
  end

  def scratch_space
    ScratchSpace.with_privacy(session[:user_id]) {
      case request.method
      when :put
        # save scratch space
        space = get_scratch_space_from_params()

        # TODO log changes
        
        send_json(get_ids_from_scratch_space(space))
      when :get
        space = ScratchSpace.find(params[:id])
        tables = []
        
        space.scratch_space_tables.each do |table|
          script_data = []
          table.procedures.each do |script|
            script_data << {'id' => script.id, 'title' => script.title}
          end
          
          tables << {
            'id' => table.id,
            'title' => table.title,
            'dataJson' => table.data_json,
            'notes' => table.notes,
            'scriptData' => script_data,
            'log' => table.log
          }
        end
        
        space_data = {
            'id' => space.id, 
            'title' => space.title, 
            'description' => space.description,
            'ownerId' => space.person.id,
            'spaceIsPrivate' => space.private,
            'tables' => tables
        }
        
        send_json(space_data)
      else
        render(:text => 'Unsupported HTTP method')
        return
      end
    }
  rescue ActiveRecord::RecordNotFound => e
    render :text => "Either this scratch space does not exist, or you do not have permission to view it", :status => "404"
  rescue Exception => e
    logger.warn("Error: #{e}\n" + "#{e.backtrace.join("\n")}\n")
    render :text => "Error: #{e}", :status => "500"
  end

  def delete_scratch_space
    ScratchSpace.with_privacy(session[:user_id]) {
        case request.method
        when :post
            space = ScratchSpace.find(params[:id])
            for table in space.scratch_space_tables
                table.destroy
            end
            space.destroy

            render :text => "Scratch space deleted"

        else
            render(:text => 'Unsupported HTTP method')
            return
        end
    }
  rescue ActiveRecord::RecordNotFound => e
    render :text => "Either this scratch space does not exist, or you do not have permission to delete it", :status => "404"
  rescue Exception => e
    logger.warn("Error: #{e}\n" + "#{e.backtrace.join("\n")}\n")
    render :text => "Error: #{e}", :status => "500"
  end
  
    def usagelog
        Procedure.with_privacy(session[:user_id]) {
            # person must be allowed to be nil because you should be able to
            # call usagelog when you are not logged in
            person = (session[:user_id] == nil) ? nil : Person.find(session[:user_id])

            if not params[:script].nil?
                procedure = Procedure.find(params[:script])
            else
                procedure = nil
            end

            if params[:time].nil?
                moddate = Time.now.utc
            else
                moddate = params[:time]
            end

            event = params[:event].to_i
            extra = params[:extra]

            UsageLog.create(
                :procedure => procedure,
                :person => person,
                :created_at => moddate,
                :event => event,
                :extra => extra,
                :version => params[:version]
            )
            render :text => "OK"
        }
    rescue Exception => e
        logger.warn("Error: #{e}\n" + "#{e.backtrace.join("\n")}\n")
        render :text => "Error logging event: #{e}", :status => "500"
    end

    def viewed
        # Note that this privacy scope means that you can't log a view event
        # on a procedure you do not have access to
        Procedure.with_privacy(session[:user_id]) {
            procedure = Procedure.find(params[:id])
            person = (session[:user_id] == nil) ? nil : Person.find(session[:user_id])
            if person.nil?
                raise "Must be logged in to record viewing usage"
            end
                
            ProcedureView.create(
                :procedure => procedure,
                :person => person,
                :viewed_at => Time.now.utc
            )
            
            # return something
            out = {
                :id => procedure.id,
                :times_viewed => ProcedureView.count(:conditions =>
                    ['procedure_id = ?', procedure.id])
            }
            send_json(out, params[:callback])
        }
    rescue Exception => e
        logger.warn("Error: #{e}\n" + "#{e.backtrace.join("\n")}\n")
        render :text => "Error logging view event: #{e}", :status => "500"
    end

    def executed
        Procedure.with_privacy(session[:user_id]) {
            procedure = Procedure.find(params[:id])
            person = (session[:user_id] == nil) ? nil : Person.find(session[:user_id])
            if person.nil?
              raise "Must be logged in to record execution usage"
            end
                

            execution_time = Time.now.utc
            p=ProcedureExecute.create(
                :procedure => procedure,
                :person => person,
                :executed_at => execution_time 
                )
            procedure.usagecount += 1
            procedure.last_executed_at=execution_time
            procedure.save
                                                 
            # return something
            out = {
                :id => procedure.id,
                :times_executed => procedure.usagecount
            }
            send_json(out, params[:callback])
        }
    rescue Exception => e
        logger.warn("Error: #{e}\n" + "#{e.backtrace.join("\n")}\n")
        render :text => "Error: #{e}", :status => "500"
    end

    def testcase
        case request.method
        when :get
            # retreive one or more testcases
            if params[:id].nil?
                tcs = Testcase.find(:all, :order => 'id asc')
                out = tcs.map {|tc| makeJSONTestcase(tc)}
            else
                tc = Testcase.find(params[:id])
                if tc.nil?
                    # error
                    out = {'error' => 'No testcase found'}
                else
                    out = makeJSONTestcase(tc)
                end
            end
            send_json(out, params[:callback])
        when :post
            # POST
            ['url', 'xpath', 'slop'].each {|reqparm|
                if params[reqparm].nil?
                    # TODO: raise error
                    out = {'error' => "Required paramater #{reqparm} not found"}
                    send_json(out, params[:callback])
                    return
                end
            }
            tc = nil
            if params[:id]
                tc = Testcase.find(params[:id])
                logger.warn("Using existing testcase # #{params[:id]}")
            end
            if tc.nil?
                tc = Testcase.new(
                    :url => params[:url],
                    :target => params[:xpath],
                    :slop => params[:slop])
            else
                tc.url = params[:url]
                tc.target = params[:xpath]
                tc.slop = params[:slop]
            end
            if not params[:act].nil?
                tc.action = params[:act]
            end
            if not params[:text].nil?
                tc.text = params[:text]
            end
            if not params[:name].nil?
                tc.name = params[:name]
            end
            if not params[:verify_slop].nil?        
                    tc.verify_slop = params[:verify_slop]
            end
            if not tc.name
                tc.name = "Testcase #{tc.id}"
            end
                        tc.save

            # return something
            out = makeJSONTestcase(tc)
            send_json(out, params[:callback])
        when :delete
            # kind of klunky to call the before_filter like this, but it
            # seems to work
            require_admin
            unless performed?
                if Testcase.exists?(params[:id])
                    Testcase.delete(params[:id])
                    render(:text => 'success')
                else
                    render(:text => 'failure',:status=> 404)
                end
            end
        else
            render(:text => 'Unsupported HTTP method')
        end
    rescue Exception => e
        logger.warn("Error: #{e}\n" + "#{e.backtrace.join("\n")}\n")
        render :text => "Error: #{e}", :status => "500"
    end

    # ----------------------------------------------------------------------
    # Popular queries

    def scripts
        Procedure.with_privacy(session[:user_id]) {
            limit = (params[:limit] || 20).to_i
            page = (params[:page] || 1).to_i
            @procs = Procedure.procedures_sorted_by(getSortOrder(params[:sort]),page,limit)
            ret = makeJSONProcedureList(@procs)
            send_json(ret, params[:callback])
        }
    rescue Exception => e
        logger.warn("Error: #{e}\n#{e.backtrace.join("\n")}\n")
        render :text => "Error: #{e}", :status => "500"
    end

    # Maybe these should reuse the procedure function above
    def popular
        redirect_to :controller => 'api', :action => 'scripts', :sort => 'usage'
    end

    def editorspicks
        Procedure.with_privacy(session[:user_id]) {
            @procs = BestBet.find_all_procedures
            @procs = @procs.delete_if { |p| p.nil? }
            limit = (params[:limit] || 20).to_i
            if limit != -1 
              @procs = @procs.paginate(:per_page=> limit)
            end
            ret = makeJSONProcedureList(@procs)
            send_json(ret, params[:callback])
        }
    rescue Exception => e
        logger.warn("Error: #{e}\n" + "#{e.backtrace.join("\n")}\n")
        render :text => "Error: #{e}", :status => "500"
    end

    def person
      Procedure.with_privacy(session[:user_id]) {
        person = nil
        if not params[:id].nil?
          person = Person.find_by_shortname(params[:id])
        else
          person = (session[:user_id].nil?) ? nil : Person.find(session[:user_id])
        end

        if person.nil?
          raise "No person specified"
        end

        # Check If-Modified-Since
        if request.env.include? 'HTTP_IF_MODIFIED_SINCE'
          # make sure the since_date is in UTC for comparison in the
          # database
          since_date = Time.parse(request.env['HTTP_IF_MODIFIED_SINCE']).utc
          procs = person.procedures.find(:all, :conditions => ['modified_at > ?',
            since_date])
          if procs.length == 0
            # nothing was modified since this time
            render :nothing => true, :status => 304
            return
          end
        end
        # If we get here, then something was modified recently, so we can
        # return the full list
          
        if person.procedures.nil?
          procs = []
        else
          limit = (params[:limit] || 20).to_i
          find_options = {:order=> "modified_at DESC", :conditions => [ "procedures.person_id=?",person.id]}
          if limit != -1
            find_options[:limit] = limit 
          end
          procs = Procedure.find(:all,find_options)
        end
        if procs.length >= 1
          most_recent = procs[0].modified_at
          response.headers['Last-Modified'] = most_recent.rfc2822
        end
        ret = makeJSONProcedureList(procs)
        send_json(ret, params[:callback])
      }
    rescue Exception => e
      logger.warn("######Error in api/person: #{e}\n" +
            "#{e.backtrace.join("\n")}\n")
            render :text => "Error: #{e}", :status => "500"
    end

    def byurl
        Procedure.with_privacy(session[:user_id]) {
            # TL: don't compute byurl on AWS, only internally, because it
            # kills the server
            client_version = request.env["HTTP_COSCRIPTERVERSION"]
            if not client_version.nil? and (client_version <=> "1.700")<0
                @procs = []
            else
                url = params[:q]
                limit = params[:limit] || 20

                @procs = Procedure.byurl(url)
                if limit != -1
                  @procs = @procs.paginate(:per_page => limit )
                end
            end
            ret = makeJSONProcedureList(@procs)
            send_json(ret, params[:callback])
        }
    rescue Exception => e
        logger.warn("Error: #{e}\n" + "#{e.backtrace.join("\n")}\n")
        render :text => "Error: #{e}\n\n" +
            "#{e.backtrace.join("\n")}\n", :status => "500"
    end

    # this will return at most 20 recently-touched scripts
    def recently_touched
        Procedure.with_privacy(session[:user_id]) {
            max = 20
            person = logged_in_user()
            procs = procedures_recently_touched(person, max).collect{|p| p.procedure}
            if params[:limit].nil?
                limit = 20
            else
                limit = params[:limit].to_i
            end
            if limit != -1
              procs = procs.paginate(:per_page => limit)
            end
            ret = makeJSONProcedureList(procs)
            send_json(ret, params[:callback])
        }
    rescue Exception => e
        logger.warn("Error: #{e}\n" + "#{e.backtrace.join("\n")}\n")
        render :text => "Error: #{e}\n\n" + "#{e.backtrace.join("\n")}\n",
            :status => "500"
    end

    # ----------------------------------------------------------------------
    # Return the scripts CoCo searches for the logged-in user
    def coco
      Procedure.with_privacy(session[:user_id]) {
        person = nil
        if not params[:id].nil?
          person = Person.find_by_shortname(params[:id])
        else
          person = (session[:user_id].nil?) ? nil : Person.find(session[:user_id])
        end

        if person.nil?
          raise "No person specified"
        end

        # Check If-Modified-Since
        if request.env.include? 'HTTP_IF_MODIFIED_SINCE'
          # make sure the since_date is in UTC for comparison in the
          # database
          since_date = Time.parse(request.env['HTTP_IF_MODIFIED_SINCE']).utc
          proc_modified_since = person.procedures.find(:all,
            :conditions => ['modified_at > ?', since_date])

          recent_modified_since = procedures_recently_touched(person, 20,
            since_date)

          if proc_modified_since.length == 0 and\
            recent_modified_since.length == 0
            # nothing was modified since this time
            render :nothing => true, :status => 304
            return
          end
        end
        # If we get here, then something was modified recently, so we can
        # return the full list
          
        if person.procedures.nil?
          procs = []
        else
          find_options = {:order=> "modified_at DESC", :conditions => [ "procedures.person_id=?",person.id]}
          procs = Procedure.find(:all,find_options)
        end

        proc_evs = procedures_recently_touched(person, 20)

        most_recent = -1
        if procs.length >= 1
          most_recent = procs[0].modified_at
        end
        if proc_evs.length >= 1
          effective_date = proc_evs[0].effective_date
          if effective_date > most_recent
            most_recent = effective_date
          end
        end
        if most_recent != -1
          response.headers['Last-Modified'] = most_recent.rfc2822
        end

        procs += proc_evs.collect { |p| p.procedure }
        ret = makeJSONProcedureList(procs)
        send_json(ret, params[:callback])
      }
    rescue Exception => e
      logger.warn("######Error in api/coco: #{e}\n" +
            "#{e.backtrace.join("\n")}\n")
            render :text => "Error: #{e}", :status => "500"
    end
    # ----------------------------------------------------------------------

    def favorites
        Procedure.with_privacy(session[:user_id]) {
            person = logged_in_user()
            procs = person.favorite_scripts
            procs = procs.delete_if { |p| p.nil? }
            procs = procs.sort { |x, y| y.modified_at <=> x.modified_at }
            ret = makeJSONProcedureList(procs)
            send_json(ret, params[:callback])
        }
    rescue Exception => e
        logger.warn("Error: #{e}\n" + "#{e.backtrace.join("\n")}\n")
        render :text => "Error: #{e}\n\n" + "#{e.backtrace.join("\n")}\n",
            :status => "500"
    end

    # ----------------------------------------------------------------------
    def store
        person = (session[:user_id] == nil) ? nil : Person.find(session[:user_id])
        if person.nil?
            raise "Must be logged in to access store"
        end
        dbname = params[:id]
        case request.method
        when :get
            userdata = UserData.find_by_person_id_and_name(person.id, dbname)
            if userdata.nil?
                # default database value
                userdata = ""
            else
                userdata = userdata.value
            end
            out={'value'=>userdata};
            send_json(out, params[:callback])
            #  render :text => userdata
        when :post
            name = params[:id]
            value = params[:value]
            userdata = UserData.find_by_person_id_and_name(person.id, name)
            if userdata.nil?
                userdata = UserData.new
            end
            userdata.person = person
            userdata.name = name
            userdata.value = value
            userdata.save!
            render :text => "Data saved successfully"
        end
    rescue Exception => e
        logger.warn("Error: #{e}\n" + "#{e.backtrace.join("\n")}\n")
        render :text => "Error: #{e}", :status => 500
    end

    # ----------------------------------------------------------------------
    # finding approximate matches based on a web page
    def find_approximate
        Procedure.with_privacy(session[:user_id]) {
            term_param = params[:terms]
            if term_param.nil?
                procs = []
            else
                terms = term_param.split
                procs = Procedure.find_all_by_title(term_param)
                procs = procs | Procedure.find_approximate(terms)
                procs = procs | Tag.find_by_keyword(terms)
            end
            ret = makeJSONProcedureList(procs)
            send_json(ret, params[:callback])
        }
    end

    # ----------------------------------------------------------------------
    # Ping the server to see if it's up
    def ping
        # attempt to retrieve editors' picks scripts as a test for whether
        # the server is up.  In the future we can do more complex things here
        Procedure.with_privacy(session[:user_id]) {
            @procs = BestBet.find_all_procedures
        }
        ret = {
            'coscripter-login-url' => url_for(:controller => 'login',
                    :action => 'login', :only_path => false),
            'coscripter-myscripts-url' => url_for(:controller => 'browse',
                    :action => 'person', :only_path => false),
            'coscripter-favorite-url' => url_for(:controller => 'browse',
                    :action => 'home', :only_path => false)
        }
        send_json(ret)
    rescue Exception => e
        render :text => "Error, server is not up\n#{e}\n", :status => 500
    end

    def sloplines 
        contains = params[:contains]
        Procedure.with_privacy(session[:user_id]) {
            procedures = Procedure.find(:all,:select=>"procedures.body,procedures.id",:limit=>params[:limit])
            sloplines = [] 
            procedures.each{|p|
                procsSlop = [] ;
                p.steps.each{|s|
                    step_number = 0 ;
                    step_number = step_number +1
                    procedure_id = p.id
                    slop = s 
                    procsSlop << {'step_number'=>step_number,'procedure_id' => procedure_id,'slop'=>slop} unless contains && s.match(contains) == nil 
                }
                sloplines.concat(procsSlop)
            }
            # return something
            out = sloplines 
            send_json(out, params[:callback])
        }  
    end

    def etsfeed
        @page = (params[:page] ||=1).to_i
        @items_per_page = (params[:perpage] ||= 1000).to_i
        @offset = (@page-1)*@items_per_page
        @tags = Tag.find(:all, :include=>[:procedure,:person],:joins=>"inner join procedures on ( procedures.id = tags.procedure_id and procedures.private = false)",:limit=>@items_per_page,:offset=>@offset)
        logger.warn("found #{@tags.length} tags")
    rescue Exception => e
        logger.warn("Error: #{e}\n#{e.backtrace.join("\n")}\n")
        render :text => "Error: #{e}", :status => "500"
    end

    # ----------------------------------------------------------------------
    # Unimplemented
    def rate
    end

    def tag
    end

    # ----------------------------------------------------------------------
    # Retrieve scripts that contain this step
    def find_with_step
        Procedure.with_privacy(session[:user_id]) {
            step = params[:step]
            scripts = Procedure.find(:all,
                :conditions => "body rlike '\\\\*[[:space:]]+#{step}[^\\n]*'"
                )
            ret = makeJSONProcedureList(scripts)
            send_json(ret, params[:callback])
        }
    rescue Exception => e
        logger.warn("Error: #{e}\n#{e.backtrace.join("\n")}\n")
        render :text => "Error: #{e}", :status => "500"
    end

    def useractivity
      user = Person.find_by_shortname(params[:id])
      limit = (params[:limit].nil?)?15 : params[:limit]
      if user.nil?
        render :text => "this user does not exist", :status => "404"
      else
        activity = user.social_network_activity(:social_network => [ user ],:limit=>limit)
        if activity.nil?
          render :text => "This user does not exist", :status => "404"
        else
          send_json(activity)
        end
      end
    end

    # Return scripts that I tagged with the specified tag(s)
    def mytag
        Procedure.with_privacy(session[:user_id]) {
            user = logged_in_user()
            if params[:id].nil?
                send_json([], params[:callback])
                return
            end
            tagset = params[:id].split
            # array of arrays of scripts matching each tag
            proclist = []
            for tag in tagset
                tags = Tag.find_all_by_person_id_and_clean_name(user.id, tag)
                procs = tags.collect { |t| t.procedure }
                procs = procs.delete_if { |p| p.nil? }
                # procs is the set of procedures that matches this tag
                proclist.push(procs)
            end
            # now we want to return all procedures that match all tags
            # (AND)
            if proclist.length > 0
                p = proclist.pop
                while proclist.length > 0
                    p = p & proclist.pop
                end
                proclist = p
            end 
            proclist.uniq!

            ret = makeJSONProcedureList(proclist)
            send_json(ret, params[:callback])
        }
    end

    # Return scripts that anyone tagged with the specified tag(s)
    # Note that this returns scripts that personA tagged tagA and personB
    # tagged tagB, NOT all scripts that personA tagged tagA and tagB
    def alltags
        Procedure.with_privacy(session[:user_id]) {
            if params[:id].nil?
                send_json([], params[:callback])
                return
            end
            tagset = params[:id].split
            proclist = []
            for tag in tagset
                tags = Tag.find_all_by_clean_name(tag)
                procs = tags.collect { |t| t.procedure }
                procs = procs.delete_if { |p| p.nil? }
                proclist.push(procs)
            end
            # now we want to return all procedures that match all tags
            # (AND)
            if proclist.length > 0
                p = proclist.pop
                while proclist.length > 0
                    p = p & proclist.pop
                end
                proclist = p
            end 
            proclist.uniq!
            ret = makeJSONProcedureList(proclist)
            send_json(ret, params[:callback])
        }
    end

        def whoami
            unless session[:user_id].nil?
                @user = Person.find(session[:user_id]) 
                # don't want all user data to be rendered ... so maybe name,id and shortname is ok
                
                send_json({ 
                    :person => {
                    :name => @user.name,
                    :id=>@user.id
                }},params[:callback])
            else
                render :text => "Not Logged In"
            end 
        
        end

    # ----------------------------------------------------------------------
    # POS tagging
    def postag
        text = params[:q]
        # Stubbed out until I find a license-friendly POS tagger
        tokens = text.split
        tags = tokens.collect { |t| "NN" }
        send_json({'tokens' => tokens, 'tags' => tags}, params[:callback])
    end

# ----------------------------------------------------------------------
    # Helper functions
    protected
    def makeJSONTestcase(tc)
        out = {'id' => tc.id,
            'url' => tc.url,
            'xpath' => tc.target,
            'slop' => tc.slop,
                        'verify_slop' => tc.verify_slop
            }
        if not tc.action.nil?
            out['act'] = tc.action
        end
        if not tc.text.nil?
            out['text'] = tc.text
        end
        if not tc.name.nil?
            out['name'] = tc.name
        end
        out
    end
    
    def makeJSONProcedure(script)
        scripturl = url_for(:controller => 'lite',
            :action => 'script',
            :id => script,
            :only_path => false)
        jsonurl = url_for(:controller => 'api',
            :action => 'script',
            :id => script,
            :only_path => false)
        koalescence_url = url_for(:controller => "browse",
          :action => "script", :id => script, :only_path => false)
        executed_url = url_for(:controller => 'api', :action => 'executed',
          :only_path => false)
        save_url = url_for(:controller => 'api', :action => 'script',
          :only_path => false)
        creator = { 'name' => script.person.name,
          'email' => script.person.shortname,
          'shortname' => script.person.shortname
          }

        ret = {'id' => script.id,
          'title' => script.title,
          'creator' => creator,
          'body' => script.body,
          'body-html' => render_to_string(:partial => "scriptbody",
            :object => script.body),
          'modified-at' => script.modified_at,
          'private' => script.private?,
          'coscript-url' => 'coscript:' + scripturl,
          'coscript-run-url' => 'coscriptrun:' + scripturl,
          'coscript-json-url' => 'coscript:' + jsonurl,
          'json-url' => jsonurl,
          'coscript-run-json-url' => 'coscriptrun:' + jsonurl,
          'coscripter-wiki-url' => koalescence_url,
          'coscripter-executed-url' => executed_url,
          'coscripter-save-url' => save_url,
          # these are obsolete, I think (TL 10/29/2007)
          'koalescence-url' => koalescence_url,
          'koalescence-lite-url' => scripturl,
          'coscripter-url' => scripturl,
          }
        if logged_in?
            p = logged_in_user()
            ret['session_user'] = {
              'email' => p.shortname,
              'shortname' => p.shortname,
              'name' => p.name }
        end
        return ret
    rescue Exception => e
        logger.warn("Error dumping JSON: #{e}")
        return {'error' => e}
    end

    def makeJSONProcedureList(procs)
        procs.map { |proc|
          makeJSONProcedure(proc)
        }
    end

    private 
    def log_client
      client_version = request.env["HTTP_COSCRIPTERVERSION"];
      logger.warn("log client: COSCRIPTERVERSION = #{client_version}")
      UsageLog.new( :version =>request.env["HTTP_COSCRIPTERVERSION"],
                        :extra => request.remote_ip ,
                        :person_id=>0,
                        :event =>0 ) unless client_version.nil?
      rescue  Exception => e
        logger.warn("Error: #{e}\n" + "#{e.backtrace.join("\n")}\n")
    end

end
