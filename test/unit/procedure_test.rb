# (C) Copyright IBM Corp. 2010
require File.dirname(__FILE__) + '/../test_helper'

class ProcedureTest < ActiveSupport::TestCase

  def setup
    @tessa = Person.find(1)
    @jimmy = Person.find(2)
  end

  # Replace this with your real tests.
  def test_create
    p = Procedure.find(1)
    assert_equal "Tessa Lau", p.person.name
    assert_equal "tessalau@us.ibm.com", p.person.email
    assert_equal 1, p.id
    assert_equal "First Procedure", p.title
    assert_equal "* go to google.com\n* type IBM\n* click search button",
      p.body
  end

  def test_byurl
    l = Procedure.byurl("about:blank")
    assert_equal 0, l.length
  end

  def test_numsteps
    p = Procedure.find(1)
    assert_equal 3, p.num_steps
    p = Procedure.find(2)
    assert_equal 0, p.num_steps
    p = Procedure.find(3)
    assert_equal 3, p.num_steps
    p = Procedure.find(4)
    assert_equal 3, p.num_steps
    p = Procedure.find(5)
    assert_equal 3, p.num_steps
    p = Procedure.find(6)
    assert_equal 0, p.num_steps
  end

  def test_steps
    p = Procedure.find(1)
    assert_equal "go to google.com", p.steps[0]
    assert_equal "type IBM", p.steps[1]
    assert_equal "click search button", p.steps[2]
  
    p = Procedure.find(2)
    assert_equal 0, p.steps.length
  
    p = Procedure.find(3)
    assert_equal "step one", p.steps[0]
    assert_equal "step 2", p.steps[1]
    assert_equal "step 3", p.steps[2]
  
    p = Procedure.find(4)
    assert_equal "step 1", p.steps[0]
    assert_equal "step 2", p.steps[1]
    assert_equal "step 3", p.steps[2]
    
    p = Procedure.find(5)
    assert_equal "go to google.com", p.steps[0]
    assert_equal "type koala", p.steps[1]
    assert_equal "press search", p.steps[2]
  
	p = Procedure.find(19)
	assert_equal "click the \"foo\" link", p.steps[0]
	assert_equal "click the \"bar\" link", p.steps[1]
	assert_equal "click the \"baz\" link", p.steps[2]
  end


  def test_privacy_filter
    public_procs = Procedure.with_privacy {
      Procedure.find(:all)
    }
    all_procs = Procedure.find(:all)
	private_procs = Procedure.find_all_by_private(true)

    privproc = Procedure.find(7)
    assert public_procs.index(privproc).nil?

    assert_equal all_procs.length - private_procs.length, public_procs.length
  end

  def test_unicode
    p = Procedure.find(10)
    assert_equal "Iñtërnâtiônàlizætiøn title", p.title
  end

  def test_most_recent_usage
    p = Procedure.find(12)
    assert_equal "--- 2007-07-09 15:32:00 Z\n", p.most_recent_usage.to_yaml

    p = Procedure.find(13)
    assert_equal "--- 2007-07-09 17:32:00 Z\n", p.most_recent_usage.to_yaml
  end
end
