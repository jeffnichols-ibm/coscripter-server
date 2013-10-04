# (C) Copyright IBM Corp. 2010

require 'digest/sha1'

class StandaloneController < ApplicationController
    layout "browse"

	# Create a new user in standalone mode
	def newuser
		# Set up the redirect variable because it's used by both GET and
		# POST methods
		@redirect = params['redirect']

		if request.post?
			# Put their credentials in the database
			email = params[:user][:email]

			if StandaloneUser.find_by_email(email)
				flash[:notice] = "This email address has already been registered"
				return
			end

			@user = StandaloneUser.new
			@user.email = email
			d = Digest::SHA1.new
			d.update(params[:user][:password])
			@user.password = d.hexdigest
			@user.save!

			# Log them in
			user = Person.new_by_email(email)
			session[:user_id] = user.id

			# Redirect them to wherever they were going
			if @redirect
				redirect_to @redirect
			else
				redirect_to :controller => :browse, :action => :index
			end
		end
	end
end
