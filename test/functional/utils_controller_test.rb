# (C) Copyright IBM Corp. 2010
require File.dirname(__FILE__) + '/../test_helper'
require 'utils_controller'

# Re-raise errors caught by the controller.
class UtilsController; def rescue_action(e) raise e end; end

class UtilsControllerTest < ActionController::TestCase
  def setup
    @controller = UtilsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
