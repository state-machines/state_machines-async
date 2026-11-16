# frozen_string_literal: true

require 'test_helper'

class AsyncAssertionsTest < StateMachinesTest
  class Shuttle
    state_machine :state, initial: :grounded do
      event(:launch) { transition grounded: :flying }
    end

    state_machine :hatch, initial: :closed, async: true do
      event(:open_hatch) { transition closed: :open }
    end
  end

  def setup
    @shuttle = Shuttle.new
  end

  def assert_assertion_fails(pattern, &)
    error = assert_raises(Minitest::Assertion, &)
    assert_match pattern, error.message
    error
  end

  def test_includes_the_core_assertions
    assert_sm_state(@shuttle, :grounded)
    assert_sm_immediate_execution(@shuttle, :launch)
  end

  def test_immediate_execution_fails_for_an_event_returning_an_async_task
    @shuttle.define_singleton_method(:launch!) do
      self.state = 'flying'
      ::Async::Task.allocate
    end
    assert_assertion_fails(/but it returned Async::Task/) { assert_sm_immediate_execution(@shuttle, :launch) }
  end

  def test_sync_and_async_mode
    assert_sm_sync_mode(@shuttle, :state)
    assert_sm_async_mode(@shuttle, :hatch)
    assert_assertion_fails(/to be in sync mode, but async mode is enabled/) { assert_sm_sync_mode(@shuttle, :hatch) }
    assert_assertion_fails(/to have async mode enabled, but it's in sync mode/) { assert_sm_async_mode(@shuttle, :state) }
  end

  def test_has_async
    assert_sm_has_async(@shuttle)
    assert_sm_has_async(@shuttle, %i[hatch])
    assert_assertion_fails(/these don't: \[:state\]/) { assert_sm_has_async(@shuttle, %i[state hatch]) }
    assert_assertion_fails(/these have async enabled: \[:hatch\]/) { assert_sm_all_sync(@shuttle) }
  end

  def test_async_methods
    assert_sm_async_methods(@shuttle)
    assert_sm_thread_safe_methods(@shuttle)
    assert_sm_async_event_methods(@shuttle, :open_hatch)
    assert_assertion_fails(/Expected no async methods/) { assert_sm_no_async_methods(@shuttle) }
  end
end
