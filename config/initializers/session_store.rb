# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => 'coscripter_session_id',
  :expire_after => 3.months 
}
#ActionController::Base.session_options[:session_key] = 'coscripter_session_id'


#ActionController::Base.session = {
#  :key         => '_testapp_session',
#  :secret      => '3df7e7469d6fb1d869b64547f8801e503db7d412c33b86b6c4ff8d6f3159c1414d9b9ae1093a1b737cf1481206c041a455c82021d813b8a5af0f8b30b8839abc'
#}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
