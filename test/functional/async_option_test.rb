# frozen_string_literal: true

require 'test_helper'

# The async: option, which the core refuses without this gem, on creation and
# on reopening
class AsyncOptionTest < StateMachinesTest
  # An integration making its machines async by default
  module AsyncByDefault
    include StateMachines::Integrations::Base

    @defaults = { async: true }
  end

  def setup
    @klass = Class.new
    StateMachines::Integrations.register(AsyncByDefault)
  end

  def teardown
    StateMachines::Integrations.reset
  end

  def test_should_enable_async_mode_from_an_integration_default
    @klass.state_machine(:status, integration: :async_by_default, initial: :idle) do
      event(:run) { transition idle: :done }
    end

    assert_sm_async_mode(@klass.new, :status)
    assert_sm_async_event_methods(@klass.new, :run)
  end

  def test_should_let_the_caller_turn_an_integration_default_off
    @klass.state_machine(:status, integration: :async_by_default, initial: :idle, async: false)

    assert_sm_sync_mode(@klass.new, :status)
  end

  def test_should_enable_async_mode_on_creation
    @klass.state_machine(:status, initial: :docked, async: true) do
      event(:launch) { transition docked: :flying }
    end

    assert_predicate @klass.state_machine(:status), :async_mode_enabled?
    assert_predicate @klass.state_machine(:status), :claims_transitions?
    assert_sm_async_event_methods(@klass.new, :launch)
  end

  def test_should_leave_async_mode_off_for_async_false
    @klass.state_machine(:status, initial: :docked, async: false)

    refute_predicate @klass.state_machine(:status), :async_mode_enabled?
    refute_predicate @klass.state_machine(:status), :claims_transitions?
  end

  def test_should_leave_async_mode_off_without_the_option
    @klass.state_machine(:status, initial: :docked)

    assert_sm_all_sync(@klass.new)
    assert_sm_no_async_methods(@klass.new)
  end

  def test_should_accept_async_when_reopening
    @klass.state_machine(:status, initial: :docked)
    @klass.state_machine(:status, async: true)

    assert_sm_async_mode(@klass.new, :status)
  end

  def test_should_list_async_among_the_reopenable_options
    machine = @klass.state_machine(:status, initial: :docked)

    assert_equal %i[initial async], machine.reopen_options
  end

  def test_should_apply_async_to_the_copy_when_reopened_in_a_subclass
    @klass.state_machine(:status, initial: :docked)
    subclass = Class.new(@klass)
    subclass.state_machine(:status, async: true)

    assert_sm_async_mode(subclass.new, :status)
    assert_sm_sync_mode(@klass.new, :status)
  end

  def test_should_apply_initial_with_async
    @klass.state_machine(:status, initial: :docked, async: true) do
      state :flying
    end
    @klass.state_machine(:status, initial: :flying)

    assert_equal 'flying', @klass.new.status
    assert_sm_async_mode(@klass.new, :status)
  end

  def test_should_still_refuse_options_that_only_apply_on_creation
    @klass.state_machine(:status, initial: :docked, async: true)

    error = assert_raises(ArgumentError) { @klass.state_machine(:status, attribute: :mode) }
    assert_match(/reopening it accepts only :initial, :async\z/, error.message)
  end

  def test_a_copy_gets_its_own_lock
    @klass.state_machine(:status, initial: :docked, async: true)
    object = @klass.new
    original_lock = object.state_machine_mutex

    [object.dup, object.clone].each do |copy|
      refute_same original_lock, copy.state_machine_mutex
    end
  end

  def test_marshalling_drops_the_lock
    klass = AsyncOptionTest.const_set(:Marshalled, Class.new)
    klass.state_machine(:status, initial: :docked, async: true)
    object = klass.new
    object.state_machine_mutex

    copy = Marshal.load(Marshal.dump(object))

    assert_equal 'docked', copy.status
    refute copy.instance_variable_defined?(:@_state_machine_mutex)
  end
end
