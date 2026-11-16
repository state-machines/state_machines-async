# frozen_string_literal: true

require 'test_helper'

# The :contended refusal of async machines, which claim their transitions
class RefusalReasonsTest < StateMachinesTest
  class Satellite
    state_machine :orbit, initial: :parked, async: true do
      event(:launch) { transition parked: :cruising }
    end
  end

  def test_should_report_contended_when_the_state_moves_before_the_claim
    satellite = Satellite.new
    transition = satellite.launch_transition
    satellite.orbit = 'cruising'

    refute transition.perform
    assert_equal :contended, transition.refusal
    assert_equal :contended, satellite.launch_refusal
  end

  def test_should_report_contended_only_on_the_contended_transition_in_parallel
    klass = Class.new do
      state_machine :orbit, initial: :parked, async: true do
        event(:launch) { transition parked: :cruising }
      end

      state_machine :beacon, initial: :off, namespace: 'beacon' do
        event(:light) { transition off: :on }
      end
    end
    satellite = klass.new
    launch = satellite.launch_transition
    light = satellite.light_beacon_transition
    satellite.orbit = 'cruising'

    refute StateMachines::TransitionCollection.new([launch, light]).perform
    assert_equal [:contended, nil], [launch.refusal, light.refusal]
    assert_equal [:contended, nil], [satellite.launch_refusal, satellite.light_beacon_refusal]
  end
end
