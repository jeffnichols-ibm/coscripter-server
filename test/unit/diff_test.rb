# (C) Copyright IBM Corp. 2010
require File.dirname(__FILE__) + '/../test_helper'

require 'algorithm/diff'
require 'unixdiff'

class DiffTest < ActiveSupport::TestCase

  # Replace this with your real tests.
  def test_diff
	a = ["line1", "line2", "line3", "line4"]
	b = ["line1", "line3", "line4", "line5"]
	d = getdiff(a, b)
	assert_equal 5, d.length
	assert_equal ["line1", " "], d[0]
	assert_equal ["line2", "-"], d[1]
	assert_equal ["line3", " "], d[2]
	assert_equal ["line4", " "], d[3]
	assert_equal ["line5", "+"], d[4]
  end
end
