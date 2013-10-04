# (C) Copyright IBM Corp. 2010
require File.dirname(__FILE__) + '/../test_helper'

class UsageLogTest < ActiveSupport::TestCase

  def setup
    @scriptview = UsageLog.find(1)
  end

  # Replace this with your real tests.
  def test_create
    assert_kind_of UsageLog, @scriptview
    assert_equal "Tessa Lau", @scriptview.person.name
    assert_equal 1, @scriptview.event
    assert_equal "Extra text", @scriptview.extra
    assert_equal "v0.1test", @scriptview.version
  end
end
