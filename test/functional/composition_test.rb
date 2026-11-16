# frozen_string_literal: true

require 'test_helper'
require 'open3'
require 'rbconfig'

# Behaviour that depends on load order or on what a fresh process loads, run
# in a child process
class CompositionTest < StateMachinesTest
  LIB = File.expand_path('../../lib', __dir__)

  # Another extension claims transitions through the core hook before this
  # gem loads; async mode must not turn its claims off.
  def test_a_claiming_extension_loaded_before_the_gem_keeps_its_claims
    output = run_fresh(<<~RUBY)
      require 'state_machines'

      module ClaimingExtension
        def claims_transitions?
          true
        end
      end
      StateMachines::Machine.prepend(ClaimingExtension)

      require 'state_machines-async'

      class ClaimedObject
        attr_accessor :runs

        state_machine :state, initial: :a do
          event(:advance) { transition a: :b }
          before_transition { sleep 0.04 }
          after_transition { |object| object.runs << :performed }
        end
      end

      object = ClaimedObject.new
      object.runs = []
      machine = ClaimedObject.state_machine
      collections = Array.new(2) { StateMachines::TransitionCollection.new([machine.events[:advance].transition_for(object)]) }
      results = collections.map { |collection| Thread.new { collection.perform } }.map(&:value)
      p [machine.claims_transitions?, results.sort_by(&:to_s), object.runs]
    RUBY

    assert_equal '[true, [false, true], [:performed]]', output
  end

  # The bare test helper entry point loads async mode
  def test_the_test_helper_alone_loads_async_mode
    output = run_fresh(<<~RUBY)
      require 'state_machines/async/test_helper'
      require 'minitest'

      klass = Class.new { state_machine(:status, initial: :idle) { event(:run) { transition idle: :done } } }
      test = Class.new(Minitest::Test) { include StateMachines::Async::TestHelper }.new('probe')
      test.assert_sm_all_sync(klass.new)
      test.assert_sm_sync_mode(klass.new, :status)
      test.assert_sm_no_async_methods(klass.new)
      p :ok
    RUBY

    assert_equal ':ok', output
  end

  private

  def run_fresh(script)
    output, status = Open3.capture2e(RbConfig.ruby, '-I', LIB, '-e', script)

    assert_predicate status, :success?, output
    output.lines.last.to_s.chomp
  end
end
