# (C) Copyright IBM Corp. 2010

class Newsletter < ActionMailer::Base
	helper ActionView::Helpers::UrlHelper
	# to get the snip() function
	helper ApplicationHelper

    def newsletter(controller, data)
        recipients  data[:person].email
        from "CoScripter Newsletter <#{$profile.site_email}>"
        today = Time.now.strftime("%d %b")
        subject "CoScripter newsletter for #{today}"
        content_type "text/html"
        headers "Reply-to" => $profile.site_email
        body data
    end

end
