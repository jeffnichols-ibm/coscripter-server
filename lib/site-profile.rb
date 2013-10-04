# (C) Copyright IBM Corp. 2010

class SiteProfile
    def needs_registration?
        false
    end

	# This should be overridden using your preferred method of
	# authentication
    def authenticate_person(id, password)
		return false
    end

	# The SMTP server that sends mail for us
	def mail_smarthost
		return "OVERRIDE_MAIL_SMARTHOST_IN_PROFILE"
	end

	# The domain mail appears to come from
	def mail_domain
		return self.hostname
	end

    def uses_single_sign_on
      return false
    end
 
	# The email address of the site administrator
	def admin_email
		return "ADMIN@OVERRIDE_ADMIN_EMAIL_IN_PROFILE"
	end

	# The email address from which site mail is sent
	def site_email
		return "SITE@OVERRIDE_SITE_EMAIL_IN_PROFILE"
	end

	# ----------------------------------------------------------------------
	# Converters between different ways to identify a person.
	# 1. Person object (represents a row in the Person table)
	# 2. email address
	# 3. shortname (string used to identify a person in URLs and other
	#    user-visible places)
	# 4. profile id (unique key used to authenticate this person)
	#
	# These are the DEFAULT, and can be overridden by specific profiles

	# Returns a person's realname given their email address.  Defaults to
	# just using the email address.  This is used for new account creation.
    def name_for_email(email)
		return email
    end

	# Return the person's profile id (key used to authenticate them during
	# login) given their email address
    def profile_id_for_email(email)
        return email
    end
    
	# Given someone's shortname, return their Person object
    def person_by_shortname(shortname)
        return Person.find_by_email(shortname)
    end
    
	# Given the person object, return their shortname
    def shortname_for_person(person)
        return person.email
    end
    
	# Given a Person object, return their email
    def email_by_person(person)
        return person.profile_id
    end

	# Given an email address, return the Person object
    def person_by_email(email)
        return Person.find_by_profile_id(email)
    end

	# ----------------------------------------------------------------------
	# Verifier for user-supplied display names

    def display_name_ok(displayname)
		# should check if this person already exists or not
        true 
    end
    
	# ----------------------------------------------------------------------
	# Whether or not we are allowed to display people's email addresses in
	# the website
    def show_email?
		return true
    end

	# Whether we are allowed to send email to users
	def send_email?
		return true
	end

	# Not currently being used
    def blog_atom_url
    end

end
