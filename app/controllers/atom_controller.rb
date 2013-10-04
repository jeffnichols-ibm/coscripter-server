# (C) Copyright IBM Corp. 2010
class AtomController < ApplicationController

  def person
    Procedure.with_privacy(session[:user_id]) {
      @author = Person.find_by_shortname(params[:id])
      if @author.nil?
	@procs = []
	@feedtitle = "#{params[:id]}'s CoScripts"
	shortname = params[:id]
      else
	limit = params[:limit]|| 30
	if limit == -1
	  @procs = @author.procedures
	else
	  @procs = @author.procedures.paginate(:order=> "modified_at DESC",:page=>params[:page],:per_page => limit)
	end
	@feedtitle = "#{@author.name}'s CoScripts"
	shortname = @author.shortname
      end

      @feedmodified = @procs.length > 0 ? @procs[0].modified_at.iso8601 :
	Time.now.utc.iso8601
      @feedlinkhtml = url_for(:controller => 'browse', :action => 'person',
			      :id => shortname, :only_path => false)
      @feedlinkatom = url_for(:controller => 'atom', :action => 'person',
			      :id => shortname, :only_path => false)
      send_data(render_to_string, :type => 'application/atom+xml',
		:disposition => 'inline')
    }
  rescue Exception => e
    logger.warn("Error: #{e}\n" +
	    "#{e.backtrace.join("\n")}\n")
	    render :text => "Error creating person feed: #{e}", :status => 500
  end

    def scripts
      Procedure.with_privacy(session[:user_id]) {
        @max = params[:num]
	@sortorder = getSortOrder(params[:sort])
	limit = (params[:limit]||30).to_i
	@procs = Procedure.procedures_sorted_by(@sortorder,params[:page],limit)

        # the optional limit parameter, if specified, limits the number of
        # entries returned.  If it's -1, return all entries.

        @feedtitle = "CoScripts#{params[:sort].nil? ? "" : " sorted by " + params[:sort]}"
        @feedmodified = @procs.collect { |x| x.modified_at }.max
	@feedlinkhtml = url_for(:controller => 'browse', :action => 'scripts',
	    :sort => @sortorder, :only_path => false)
	@feedlinkatom = url_for(:controller => 'atom', :action => 'scripts',
	    :sort => @sortorder, :only_path => false)
	send_data(render_to_string, :type => 'application/atom+xml',
          :disposition => 'inline')
      }
    rescue Exception => e
      logger.warn("Error: #{e}\n" +
	    "#{e.backtrace.join("\n")}\n")
      render :text => "Error creating scripts feed: #{e}", :status => 500
    end

    def recent
      redirect_to :controller => 'atom', :action => 'scripts',
        :sort => 'modified'
    end
end

