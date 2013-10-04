# (C) Copyright IBM Corp. 2010
class LiteController < ApplicationController
    before_filter :authorize_session_lite, :except => [ :login,
      :linkified_script, :linkified_procedure ]

    def script
      Procedure.with_privacy(session[:user_id]) {
	@procedure = Procedure.find(params[:id])
      }
    rescue ActiveRecord::RecordNotFound => e
	render :text => "This script does not exist or has been deleted.",
          :status => "404"
    end
    def procedure
      redirect_to :action => 'script', :id => params[:id]
    end

    def linkified_script
		Procedure.with_privacy(session[:user_id]) {
			@procedure = Procedure.find(params[:id])
			@linkified_script = (@procedure.body.nil? ? '' : @procedure.body)

			# Find anything that looks like a URL and make it a link
			# We're not using ApplicationHelper's linkifyUrls() because
			# the targets of the anchor tags are different. 
			bareUrlReStr = "(([A-Za-z0-9$_.+!*(),;/?:@&~=-])|%[A-Fa-f0-9]{2}){2,}(#([a-zA-Z0-9][a-zA-Z0-9$_.+!*(),;/?:@&~=%-]*))?([A-Za-z0-9$_+!*();/?:~-]))"
			urlRe = Regexp.new("(^|[ \\s\"])((ftp|http|https|mailto|file):" + bareUrlReStr)
			wwwRe = Regexp.new("(^|[ \\s\"])(www." + bareUrlReStr)
			
			@linkified_script.gsub!(urlRe, '\1<a href="javascript:openUrlInMainWindow(\'\2\')">\2</a>')
			@linkified_script.gsub!(wwwRe, '\1<a href="javascript:openUrlInMainWindow(\'http://\2\')">\2</a>')
		}
    rescue ActiveRecord::RecordNotFound => e
	render :text => "This script does not exist or has been deleted."
    end

    def edit
		Procedure.with_privacy(session[:user_id]) {
			@procedure = Procedure.find(params[:id])
		}
    rescue ActiveRecord::RecordNotFound => e
	render:text => "This script does not exist or has been deleted."
    end

    def new
		if request.get?
			@procedure = Procedure.new
		else
			if createProcedure(params[:procedure])
			else
			render :text => "Error creating procedure"
			end
		end
    end

    def update
		Procedure.with_privacy(session[:user_id]) {
			if updateProcedure(params[:id], params[:procedure])
				redirect_to :action => 'procedure', :id => params[:id]
			else
				render :text => "Error updating procedure"
			end
		}
    end

    def login
		@redirect = params['redirect']
		@thisurl = url_for(params)

		if request.get?
			session[:user_id] = nil
		else
            if firsttimeUser(params[:user]['w3login'])
                if $profile.needs_registration?
                    render :template => 'lite/notregistered'
                else
                    if Person.authenticate(params[:user]['w3login'], params[:user]['w3pass'])
                            Person.new_by_email(params[:user]['w3login']);
                            loginUser(params[:user]['w3login'])
                            redirect_to params['redirect']
                    else
                        render :text => 'Login failed, please check your password and try again'
                    end
                end
            else
	        if Person.authenticate(params[:user]['w3login'], params[:user]['w3pass'])
		    loginUser(params[:user]['w3login'])
                    redirect_to params['redirect']
                else
                    render :text => 'Login failed, please check your password and try again'
                end
            end
		end
    end

	def find_related
		Procedure.with_privacy(session[:user_id]) {
			if request.post?
				@text = params['question']
				me = logged_in_user()
				r = Wish.new
				r.wish = @text
				r.url = params['url']
				r.title = params['title']
				r.person = me
				r.save!
				redirect_to :action => :find_related, :url => params['url'],
					:title => params['title']
			else
				@cururl = params['url']
				@title = params['title']
				if @cururl
					@related = Procedure.byurl(@cururl)
					@requests = Wish.find_all_by_url(@cururl)
				else
					@related = []
					@requests = []
				end
			end
		}
	rescue
		render :text => "Error making a wish",
			  :status => "500"
	end

	# Light version for bookmarklet that doesn't show relevant scripts
	def make_wish
		if request.post?
			@text = params['question']
			me = logged_in_user()
			r = Wish.new
			r.wish = @text
			r.url = params['url']
			r.title = params['title']
			r.person = me
			r.save!
			redirect_to :action => :make_wish, :url => params['url'],
				:title => params['title']
		else
			@cururl = params['url']
			@title = params['title']
			if @cururl
				@requests = Wish.find_all_by_url(@cururl)
			else
				@requests = []
			end
		end
	end
end
