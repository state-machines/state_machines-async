# frozen_string_literal: true

require 'state_machines-async'
require 'state_machines/async/test_helper'
require 'minitest/autorun'
require 'minitest/reporters'
Minitest::Reporters.use! [Minitest::Reporters::ProgressReporter.new]

class StateMachinesTest < Minitest::Test
  include StateMachines::TestHelper

  def before_setup
    super
    StateMachines::Integrations.reset
  end
end
