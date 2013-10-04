# (C) Copyright IBM Corp. 2010
require 'test_helper'

class BlacklistTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  def test_ip_match
    ip1 = blacklists(:one)
    ip = Blacklist.find_by_ip_address(ip1.ip_address)
    assert_equal ip,ip1
  end
end
