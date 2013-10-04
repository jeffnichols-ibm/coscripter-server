# TL: for sending mail 8/2/2007
ActionMailer::Base.smtp_settings = {
  :address => $profile.mail_smarthost,
  :port => 25,
  :domain => $profile.mail_domain
}
# Set this to false to temporarily disable mail delivery
ActionMailer::Base.perform_deliveries = true
# Who should receive notification emails on errors
ExceptionNotifier.sender_address = %("CoScripter Exception" <do_not_reply@#{$profile.mail_domain}>)
ExceptionNotifier.exception_recipients = %(#{$profile.admin_email})

