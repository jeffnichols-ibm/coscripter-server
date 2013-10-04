# (C) Copyright IBM Corp. 2010
require File.dirname(__FILE__) + '/../test_helper'

class PersonTest < ActiveSupport::TestCase

  # Replace this with your real tests.
  def test_optout_default
    p = Person.new
    assert_equal false, p.optout
  end

  def test_followup_comments
    me = Person.find(1)
    comments = me.recent_procedure_comments
    target1 = ProcedureComment.find(4)
    target2 = ProcedureComment.find(5)
    assert comments.include?(target1)
    assert_equal false, comments.include?(target2)

    jimmy = Person.find(2)
    comments = jimmy.recent_procedure_comments
    assert_equal false, comments.include?(target1)
  end

  def test_social_network_activity
    me = Person.find(1)
    
    # only one person
    activities = me.social_network_activity( :social_network => [me], :limit=>20)

    my_scripts = [me.procedures.uniq.length, 20].min
    my_uniq_executions = me.procedure_executes.collect{|e| e.procedure.id unless ( e.procedure.nil? or e.procedure.private? )}.uniq.length
    my_modifications = me.changes.collect{|c| c.procedure.id unless ( c.procedure.nil? or c.procedure.private) }.uniq.length

    assert_equal my_scripts,activities[:created].length
    assert_equal my_uniq_executions,activities[:executed].length
    assert_equal my_modifications,activities[:modified].length
    
    # check that limit is working
    activities = me.social_network_activity( :social_network => [me], :limit=>1)

    assert_equal 1,activities[:created].length
    assert_equal 1,activities[:executed].length
    assert_equal 1,activities[:modified].length

    # two people
    the_other_guy = Person.find(2)
    our_procedures =me.procedures.length + the_other_guy.procedures.length
    our_uniq_executions =  my_uniq_executions + the_other_guy.procedure_executes.collect{|e| e.procedure.id unless ( e.procedure.nil? or e.procedure.private? )}.uniq.length
    our_modifications = my_modifications+  the_other_guy.changes.collect{|c| c.procedure.id unless ( c.procedure.nil? or c.procedure.private) }.uniq.length
    activities = me.social_network_activity( :social_network => [me,the_other_guy], :limit=>30)
    assert_equal our_procedures,activities[:created].length
    assert_equal our_uniq_executions,activities[:executed].length
    assert_equal our_modifications,activities[:modified].length

   end

# TL 1/11/10: Beehive doesn't seem to be working anymore; maybe it's
# socialblue now?
#   def test_beehive
#    p = Person.find(1)
#    bh_friends = p.beehive_friends
#    assert bh_friends.size >=2 
#    assert bh_friends.include?('Werner.Geyer@us.ibm.com')
#    assert bh_friends.include?('sfarrell@almaden.ibm.com')
#   end

	def test_recent_comments
		p = Person.find(5)
		comments = p.recent_procedure_comments
		assert_equal 1, comments.length
		assert_equal 2, comments[0].person.id
	end
  def test_friends
    tessa=people(:tessa)
    allen=people(:allen)
    jimmy=people(:jimmy)
    clemens=people(:clemens)

    assert jimmy.friends.include?(tessa)
    assert tessa.friends.include?(jimmy)
    assert tessa.friends.include?(allen)
    assert allen.friends.include?(tessa) == false # not automatically reciprocal

    assert_equal 2,tessa.friends.length
    assert_equal 1,jimmy.friends.length
    assert_equal 0,allen.friends.length

    allen.friends << tessa
    assert allen.friends.include?(tessa) 
    assert_equal 1,allen.friends.length

    allen.friends << tessa
    assert allen.friends.include?(tessa)
    assert_equal 1,allen.friends.length # befriending twice has no effect

    allen.friends.delete(tessa) # and remove only once even after adding twice
    assert allen.friends.include?(tessa) == false# not automatically reciprocal
    assert_equal 0,allen.friends.length

    jimmy.friends = [allen,clemens] # replace entire friends collection
    assert jimmy.friends.include?(allen)
    assert jimmy.friends.include?(clemens)
    assert jimmy.friends.include?(tessa) == false # not automatically reciprocal

    assert_equal 2,jimmy.friends.length
	
  end
end
