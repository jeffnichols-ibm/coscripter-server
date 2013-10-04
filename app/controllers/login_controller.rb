# (C) Copyright IBM Corp. 2010

class LoginController < ApplicationController
    layout "browse"

    def rescue_action(exception)
        flash[:notice] = "Login failed. Our authentication service is experiencing problems. Please try again later.\n(error: #{exception})"
		raise exception
        redirect_to :controller=>'browse',:action=>'about'
    end

    def login
      @redirect = params['redirect']
      @thisurl = url_for(params)
      @from_ibm_domain = false
      
      if @redirect.nil? or @redirect.strip == ""
        @redirect = url_for(:controller => :browse)
      end

      @credentialName = $profile.id_name
      if request.get?
        session[:user_id] = nil
      else
        if params[:user].nil?
          # we get here if the ibm.com signup page POSTed to this url
          #
          # TODO: try to extract the "w3login" field from the "ibmuid"
          # parameter given to us from the ibm.com registration form
          session[:user_id] = nil
        else
          if Person.authenticate(params[:user]['w3login'], params[:user]['w3pass'])
            if firsttimeUser(params[:user]['w3login']) 
              if $profile.needs_registration?
                session[:registerid]=params[:user]['w3login']
                redirect_to :action => 'register', :redirect=> params[:redirect]
              else
                # ok to create user here
                Person.new_by_email(params[:user]['w3login'])
                loginUser(params[:user]['w3login'])
                redirect_to @redirect
              end
            else  
              # Check if the user needs to accept the 2nd terms
              ret = loginUser(params[:user]['w3login'])
              if ret
                user = logged_in_user
                if $profile.needs_registration? and not user.accepted_alm_terms
                  redirect_to :action => "reaccept", :redirect => @redirect
                else
                  redirect_to @redirect
                end
              end
            end
          else
            flash[:notice] = 'Login failed. Please check your password and try again.'
          end
        end
      end
    end

    def logout
      session[:user_id] = nil
      flash[:notice] = 'You have been logged out.'
      redirect_to :action => params[:redirect], :controller => 'browse'
    end

     def register
        if session[:registerid].nil? && request.get? 
            session[:user_id] = nil 
            redirect_to :controller => 'login', :action => 'login', :redirect=> params[:redirect]
            return 
        end
        if request.post? && ( params[:user].nil? ||  session[:registerid].nil? )
            session[:user_id] = nil
            redirect_to :controller => 'login', :action => 'login', :redirect=> params[:redirect]
            return
        end
        @redirect = params[:redirect]
        
	@displayname = session[:screenname] 
        return unless request.post?

        displayname = params[:user]['displayname']
        if displayname == ""
            session[:user_id] = nil 
            flash[:notice] = 'You need to choose a display name.'
        elsif not $profile.display_name_ok(displayname)
            session[:user_id] = nil 
            flash[:notice] = 'The name you have chosen is already taken. Please choose another one.'
        elsif not is_username(displayname)
            session[:user_id] = nil 
            flash[:notice] = 'The name you have chosen contains characters that are not allowed.'
        end
        if displayname != "" && $profile.display_name_ok(displayname) && is_username(displayname)
          p = Person.new_by_email(session[:registerid],displayname)
          session[:user_id] = p.id
          p.accepted_alm_terms = true
          p.save
          session[:registerid] = nil 
          session[:registerpw] = nil
          redirect_to params[:redirect]
        end
    end

	def reaccept
		@redirect = params[:redirect]
		if request.post?
			p = logged_in_user
			p.accepted_alm_terms = true
			p.save

			flash[:notice] = "Thank you for accepting the updated terms and conditions"
			redirect_to @redirect
		end
	end
        
    def userexists
        name = params[:name]
        if is_username(name)
            user = Person.find_by_name(name)
            if user.nil?
                @legalname = true
                @exists = false
            else
                @legalname = true
                @exists = true 
            end
        else
            @exists = false
            @legalname = false
        end
    end

end
