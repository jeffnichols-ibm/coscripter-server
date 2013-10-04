# (C) Copyright IBM Corp. 2010
require 'ldap'
require "#{File.dirname(__FILE__)}/site-profile"

class TestProfile < SiteProfile
    attr_accessor :needs_registration
    def initialize   
            @needs_registration = true 
    end

    def needs_registration?
        return needs_registration == true 
    end

    def blog_atom_url
        'http://blogs.tap.ibm.com/weblogs/koala/feed/entries/atom'
    end

    def id_name
        "test id"
    end
    
    def display_name_ok(displayname)
        Person.find_by_name(displayname).nil?
    end
    
    def authenticate_person(id, password)
        return false 
    end

	def profilename
		return "test"
	end

	def site_email
		return "test@testdomain.com"
	end

    def profile_id_for_email(email)
        return email 
    end
    
    def person_by_shortname(shortname)
        return Person.find_by_email(shortname)
    end
    
    def shortname_for_person(person)
        return person.email
    end
    
    def email_by_person(person)
        return person.profile_id
    end

    def person_by_email(email)
        return Person.find_by_profile_id(email)
    end

    def show_email?
      return true
    end

	def send_email?
	  return true
	end

    def contact_url
      return "mailto:tessalau@us.ibm.com?subject=CoScripter%20feedback"
    end
    def blog_url
      return "http://blogs.tap.ibm.com/weblogs/koala"
    end
    def forum_url
      return "http://ibmforums.ibm.com/forums/forum.jspa?forumID=2430"
    end
    # for the Firefox extension
    def xpi_url
      return "http://koala.almaden.ibm.com/download/FirefoxExtensionXPI/coscripter.xpi"
    end
    def version_js_url
      return "http://koala.almaden.ibm.com/download/FirefoxExtensionXPI/version.js"
    end

    def hostname
        return "coscripter.almaden.ibm.com"
    end

    private
    def get_profile(email)
        uri = 'http://bluepages.ibm.com/BpHttpApis/wsapi?byInternetAddr=' +\
            email
        ret = Net::HTTP.get(URI.parse(uri))
        ret
    end
end     

