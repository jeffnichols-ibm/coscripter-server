# (C) Copyright IBM Corp. 2010

class Mailer < ActionMailer::Base

    def share(procedure_share_details)
		# procedure_share_details has instance variables:
		# subject, recipient_email, sender_email, body
		@subject    = procedure_share_details['subject']
		@body       = {}
		@recipients = procedure_share_details['recipient_email'].split(/, */)
		@from       = procedure_share_details['sender']
		@sent_on    = procedure_share_details['date'] or Time.now.utc
		@headers    = {}
		@body['body'] = procedure_share_details['body']
    end

    def comment(comment_details)
		# comment_details has instance variables:
		# subject, recipients, sender, body
		@subject    = comment_details['subject']
		@body       = {}
		@recipients = comment_details['recipients']
		@from       = comment_details['sender']
		@sent_on    = Time.now.utc
		@headers    = {}
		@body['body'] = comment_details['body']
    end

	# Email that gets sent out when a script is modified
	def script_modified(details)
		@subject = details['subject']
		@body = {}
		@recipients = details['recipients']
		@from = details['sender']
		@sent_on = Time.now.utc
		@headers = {}
		content_type "text/html"
		@body['body'] = details['body']
	end
end
