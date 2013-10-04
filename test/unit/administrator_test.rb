# (C) Copyright IBM Corp. 2010
require File.dirname(__FILE__) + '/../test_helper'

class AdministratorTest < ActiveSupport::TestCase

  # Replace this with your real tests.
  def test_create
    tessa = Person.find(1)
    jimmy = Person.find(2)

    assert_not_nil tessa.administrator
    assert_nil jimmy.administrator
  end
end
