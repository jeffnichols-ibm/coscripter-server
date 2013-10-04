# (C) Copyright IBM Corp. 2010
require File.dirname(__FILE__) + '/../test_helper'
require 'standalone-profile'

class StandaloneUserTest < ActiveSupport::TestCase

	def setup
		$profile = StandaloneProfile.new
	end

	# Make sure the test user can be authenticated
	def test_authenticate
		assert_equal true, Person.authenticate("abc@def.ghi", "mypass")
		assert_equal false, Person.authenticate("abc@def.ghi", "notmypass")
	end
end
