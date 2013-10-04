# (C) Copyright IBM Corp. 2010
require "#{File.dirname(__FILE__)}/site-profile.rb"
require 'digest/sha1'

class StandaloneProfile < SiteProfile
	# ----------------------------------------------------------------------
	# Define all your site-specific customizations here
	#

	# Hostname on which this server is deployed
    def hostname
        return "coscripter.YOURCOMPANY.COM"
    end

	# Email address for local contact
    def contact_url
      return "mailto:coscripter@YOURCOMPANY.COM?subject=CoScripter%20feedback"
    end

    # Location where the Firefox extension is installed on the server
    def xpi_url
      return "http://#{self.hostname}/download/FirefoxExtensionXPI/coscripter.xpi"
    end
    def version_js_url
      return "http://#{self.hostname}/download/FirefoxExtensionXPI/version.js"
    end

	# CoScripter blog
    def blog_url
      return nil
    end
	# Forums
    def forum_url
      return nil
    end
	# Bug tracker
    def bugtracker_url
      return nil
    end

	# The SMTP server that sends mail for us
	def mail_smarthost
		return "OVERRIDE_MAIL_SMARTHOST_IN_PROFILE"
	end

	# The domain mail appears to come from
	def mail_domain
		return self.hostname
	end

	# The email address of the site administrator
	def admin_email
		return "ADMIN@OVERRIDE_ADMIN_EMAIL_IN_PROFILE"
	end

	# ----------------------------------------------------------------------
	# Shouldn't need to change anything below here

	# Use the standalone person database to authenticate users
    def authenticate_person(id, password)
        p = StandaloneUser.find(:first, :conditions => {
			:email => id})
		if p.nil?
			return false
		end
		d = Digest::SHA1.new
		d.update(password)
		if p.password == d.hexdigest
			return true
		else
			return false
		end
    end

	# This is the subdirectory in app/views/shared that contains special
	# instructions for various pages on the site.
	def profilename
		return "standalone"
	end

    def id_name
        "CoScripter ID"
    end
end     

