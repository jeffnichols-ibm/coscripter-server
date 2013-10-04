# (C) Copyright IBM Corp. 2010
require File.dirname(__FILE__) + '/../test_helper'

class ProcedureMembershipsTest < ActiveSupport::TestCase

  def setup
   @tessa = people(:tessa)
   @jimmy = people(:jimmy)
   @allen = people(:allen)
   @clemens = people(:clemens)
  end
  # Replace this with your real tests.
  def test_truth
    assert true
  end

  def test_members
    private_procedure = procedures(:clemens_private_shared_script)
    assert 2,private_procedure.members.length
    assert private_procedure.members.include?(@tessa)
    assert private_procedure.members.include?(@jimmy)
    assert !private_procedure.members.include?(@allen)
  end

  def test_procedure_memberships
    clemens_private_shared_script = procedures(:clemens_private_shared_script)
    jimmys_private_shared_script = procedures(:jimmys_private_shared_script)
    assert_equal 2,@tessa.procedure_memberships.length
    assert_equal 1,@jimmy.procedure_memberships.length
    assert_equal 0,@allen.procedure_memberships.length 
    assert @jimmy.procedure_memberships.include?(clemens_private_shared_script)
    assert @tessa.procedure_memberships.include?(jimmys_private_shared_script)
    assert @tessa.procedure_memberships.include?(clemens_private_shared_script)
  end

  def test_add_remove_members
    private_procedure = procedures(:clemens_private_shared_script)
    initial_membercount = private_procedure.members.length 
    private_procedure.members << @allen
    assert_equal initial_membercount+1,private_procedure.members.length 
    # add members has no effect 
    private_procedure.members << @allen
    assert_equal initial_membercount+1,private_procedure.members.length 

    assert private_procedure.members.include?(@allen)
    private_procedure.members.delete(@allen) 
    assert !private_procedure.members.include?(@allen)
  end

  def test_privacy_with_memberships
    clemens_private_shared_script = procedures(:clemens_private_shared_script)
    jimmys_private_shared_script = procedures(:jimmys_private_shared_script)

    Procedure.with_privacy(@clemens.id){
      assert  Procedure.find(:all).include?(clemens_private_shared_script)
      assert !Procedure.find(:all).include?(jimmys_private_shared_script)
    }
    Procedure.with_privacy(@tessa.id){
      assert Procedure.find(:all).include?(clemens_private_shared_script)
      assert Procedure.find(:all).include?(jimmys_private_shared_script)
    }
    Procedure.with_privacy(@jimmy.id){
      assert Procedure.find(:all).include?(clemens_private_shared_script)
      assert Procedure.find(:all).include?(jimmys_private_shared_script)
    }
    Procedure.with_privacy(@allen.id){
      assert !Procedure.find(:all).include?(clemens_private_shared_script)
      assert !Procedure.find(:all).include?(jimmys_private_shared_script)
    }
   end
end
