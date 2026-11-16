# frozen_string_literal: true

require 'state_machines-async'
require 'state_machines/test_helper'

module StateMachines
  module Async
    # Assertions for async mode, on top of the core's StateMachines::TestHelper
    # (which this includes, so a test case includes only this module).
    #
    # @example Minitest
    #   class DroneTest < Minitest::Test
    #     include StateMachines::Async::TestHelper
    #
    #     def test_status_is_async
    #       assert_sm_async_mode(AutonomousDrone.new, :status)
    #     end
    #   end
    module TestHelper
      include StateMachines::TestHelper

      # === Sync Mode Assertions ===

      # Assert that a state machine is operating in synchronous mode
      #
      # @param object [Object] The object with state machines
      # @param machine_name [Symbol] The name of the state machine (defaults to :state)
      # @param message [String, nil] Custom failure message
      # @return [void]
      # @raise [AssertionError] If the machine has async mode enabled
      #
      # @example
      #   user = User.new
      #   assert_sm_sync_mode(user)                           # Uses default :state machine
      #   assert_sm_sync_mode(user, :status)                  # Uses :status machine
      def assert_sm_sync_mode(object, machine_name = :state, message = nil)
        machine = object.class.state_machines[machine_name]
        raise ArgumentError, "No state machine '#{machine_name}' found" unless machine

        async_enabled = machine.async_mode_enabled?
        default_message = "Expected state machine '#{machine_name}' to be in sync mode, but async mode is enabled"

        _sm_refute(async_enabled, message || default_message)
      end

      # Assert that async methods are not available on a sync-only object
      #
      # @param object [Object] The object with state machines
      # @param message [String, nil] Custom failure message
      # @return [void]
      # @raise [AssertionError] If async methods are available
      #
      # @example
      #   sync_only_car = Car.new  # Car has no async: true machines
      #   assert_sm_no_async_methods(sync_only_car)
      def assert_sm_no_async_methods(object, message = nil)
        async_methods = %i[fire_event_async fire_events_async fire_event_async! async_fire_event]
        available_async_methods = async_methods.select { |method| object.respond_to?(method) }

        default_message = "Expected no async methods to be available, but found: #{available_async_methods.inspect}"

        _sm_assert_empty(available_async_methods, message || default_message)
      end

      # Assert that an object has no async-enabled state machines
      #
      # @param object [Object] The object with state machines
      # @param message [String, nil] Custom failure message
      # @return [void]
      # @raise [AssertionError] If any machine has async mode enabled
      #
      # @example
      #   sync_only_vehicle = Vehicle.new  # All machines are sync-only
      #   assert_sm_all_sync(sync_only_vehicle)
      def assert_sm_all_sync(object, message = nil)
        async_machines = []

        object.class.state_machines.each do |name, machine|
          async_machines << name if machine.async_mode_enabled?
        end

        default_message = "Expected all state machines to be sync-only, but these have async enabled: #{async_machines.inspect}"

        _sm_assert_empty(async_machines, message || default_message)
      end

      # === Async Mode Assertions ===

      # Assert that a state machine is operating in asynchronous mode
      #
      # @param object [Object] The object with state machines
      # @param machine_name [Symbol] The name of the state machine (defaults to :state)
      # @param message [String, nil] Custom failure message
      # @return [void]
      # @raise [AssertionError] If the machine doesn't have async mode enabled
      #
      # @example
      #   drone = AutonomousDrone.new
      #   assert_sm_async_mode(drone)                         # Uses default :state machine
      #   assert_sm_async_mode(drone, :teleporter_status)     # Uses :teleporter_status machine
      def assert_sm_async_mode(object, machine_name = :state, message = nil)
        machine = object.class.state_machines[machine_name]
        raise ArgumentError, "No state machine '#{machine_name}' found" unless machine

        async_enabled = machine.async_mode_enabled?
        default_message = "Expected state machine '#{machine_name}' to have async mode enabled, but it's in sync mode"

        _sm_assert(async_enabled, message || default_message)
      end

      # Assert that async methods are available on an async-enabled object
      #
      # @param object [Object] The object with state machines
      # @param message [String, nil] Custom failure message
      # @return [void]
      # @raise [AssertionError] If async methods are not available
      #
      # @example
      #   drone = AutonomousDrone.new  # Has async: true machines
      #   assert_sm_async_methods(drone)
      def assert_sm_async_methods(object, message = nil)
        async_methods = %i[fire_event_async fire_events_async fire_event_async! async_fire_event]
        available_async_methods = async_methods.select { |method| object.respond_to?(method) }

        default_message = 'Expected async methods to be available, but found none'

        _sm_refute_empty(available_async_methods, message || default_message)
      end

      # Assert that an object has async-enabled state machines
      #
      # @param object [Object] The object with state machines
      # @param machine_names [Array<Symbol>] Expected async machine names
      # @param message [String, nil] Custom failure message
      # @return [void]
      # @raise [AssertionError] If expected machines don't have async mode
      #
      # @example
      #   drone = AutonomousDrone.new
      #   assert_sm_has_async(drone, [:status, :teleporter_status, :shields])
      def assert_sm_has_async(object, machine_names = nil, message = nil)
        if machine_names
          # Check specific machines
          non_async_machines = machine_names.reject do |name|
            machine = object.class.state_machines[name]
            machine&.async_mode_enabled?
          end

          default_message = "Expected machines #{machine_names.inspect} to have async enabled, but these don't: #{non_async_machines.inspect}"

          _sm_assert_empty(non_async_machines, message || default_message)
        else
          # Check that at least one machine has async
          async_machines = object.class.state_machines.select do |_name, machine|
            machine.async_mode_enabled?
          end

          default_message = 'Expected at least one state machine to have async enabled, but none found'

          _sm_refute_empty(async_machines, message || default_message)
        end
      end

      # Assert that individual async event methods are available
      #
      # @param object [Object] The object with state machines
      # @param event [Symbol] The event name
      # @param message [String, nil] Custom failure message
      # @return [void]
      # @raise [AssertionError] If async event methods are not available
      #
      # @example
      #   drone = AutonomousDrone.new
      #   assert_sm_async_event_methods(drone, :launch)  # Checks launch_async and launch_async!
      def assert_sm_async_event_methods(object, event, message = nil)
        async_method = :"#{event}_async"
        async_bang_method = :"#{event}_async!"

        has_async = object.respond_to?(async_method)
        has_async_bang = object.respond_to?(async_bang_method)

        _sm_assert(has_async, message || "Missing #{async_method} method")
        _sm_assert(has_async_bang, message || "Missing #{async_bang_method} method")
      end

      # Assert that an object has thread-safe state methods when async is enabled
      #
      # @param object [Object] The object with state machines
      # @param message [String, nil] Custom failure message
      # @return [void]
      # @raise [AssertionError] If thread-safe methods are not available
      #
      # @example
      #   drone = AutonomousDrone.new
      #   assert_sm_thread_safe_methods(drone)
      def assert_sm_thread_safe_methods(object, message = nil)
        thread_safe_methods = %i[state_machine_mutex read_state_safely write_state_safely]
        missing_methods = thread_safe_methods.reject { |method| object.respond_to?(method) }

        default_message = "Expected thread-safe methods to be available, but missing: #{missing_methods.inspect}"

        _sm_assert_empty(missing_methods, message || default_message)
      end
    end
  end
end
