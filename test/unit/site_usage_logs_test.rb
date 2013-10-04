# (C) Copyright IBM Corp. 2010
require File.dirname(__FILE__) + '/../test_helper'

class SiteUsageLogsTest < ActiveSupport::TestCase

  def setup
    @one = SiteUsageLog.find(1)
  end
  
  # Replace this with your real tests.
  def test_create
    assert_kind_of SiteUsageLog, @one
    assert_equal "Tessa Lau", @one.person.name
    assert_equal "browse", @one.controller
    assert_equal "about", @one.action
    assert_equal "/", @one.uri
    assert_equal "a1a", @one.coscripter_session_id
    assert_equal "127.0.0.1", @one.ip
  end
end
