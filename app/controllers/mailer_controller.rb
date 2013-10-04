# (C) Copyright IBM Corp. 2010

class MailerController < ApplicationController
    before_filter :authorize_session, :except => [
        :view_newsletter, :send_newsletter, :send_newsletter_to ]
	
	def view_newsletter
        if not params[:id]
            render :text => "Please specify the newsletter recipient"
			return
        end
		person = Person.find_by_profile_id(params[:id])
		if person.nil?
			render :text => "No person found for id #{params[:id]}"
			return
		end
		data = person.get_newsletter_data(14)
		if data.nil?
			render :text => "No social network activity for #{person.name}"
		else
			for val in data.keys
				#eval("@#{val} = #{data[val]}")
				self.instance_variable_set("@#{val}", data[val])
			end
#			@partial_prefix = ""
			render :template => "newsletter/newsletter"
		end
	end

    def send_newsletter
		people = [
			'tessalau@us.ibm.com',
			'cdrews@us.ibm.com',
			'acypher@us.ibm.com',
			'jameslin@us.ibm.com',
			'ehaber@us.ibm.com',
			'tlmatthe@us.ibm.com',
			'jwnichols@us.ibm.com',
			'syarosh@us.ibm.com',
			'jpbigham@us.ibm.com',
			'basmith@almaden.ibm.com']

		out = ""
		for email in people
			person = Person.find_by_email(email)
			if person.optout?
				out += "#{person.name} has opted out\n"
			else
				ret = send_newsletter_to_one_person(person)
				if ret
					out += "Newsletter sent to #{person.name}\n"
				else
					out += "#{person.name} has no social network activity, not sending email\n"
				end
			end
		end

		render :text => out
    end

	def send_newsletter_to
        if not params[:id]
            render :text => "Please specify the newsletter recipient"
			return
        end

		person = Person.find_by_profile_id(params[:id])
		ret = send_newsletter_to_one_person(person)
		if ret
			render :text => "Newsletter sent to #{person.name}\n"
		else
			render :text => "#{person.name} has no social network activity, not sending email\n"
		end
	end

	def unsub
		me = logged_in_user()
		me.optout = true
		me.save!
	end

	# Returns true iff this person has some social network activity
	def send_newsletter_to_one_person(person)
		data = person.get_newsletter_data(14)
		if not data.nil?
			# need to add in the controller to get url_for methods
			data[:controller] = self
#			data[:partial_prefix] = "../"
			Newsletter.deliver_newsletter(self, data)
			return true
		else
			return false
		end
	end

end
