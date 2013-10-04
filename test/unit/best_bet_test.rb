# (C) Copyright IBM Corp. 2010
require File.dirname(__FILE__) + '/../test_helper'

class BestBetTest < ActiveSupport::TestCase

  # Replace this with your real tests.
  def test_best_bets
    proc1 = Procedure.find(1)
    assert_nil proc1.best_bet

    proc2 = Procedure.find(2)
    assert_not_nil proc2.best_bet
  end
end
