# frozen_string_literal: true

# Async mode runs on the Fiber scheduler of the async gem, whose io-event
# native extension and scheduler support JRuby and TruffleRuby lack. Refuse
# to load there rather than run async machines synchronously.
if RUBY_ENGINE == 'jruby' || RUBY_ENGINE == 'truffleruby'
  raise LoadError, <<~ERROR
    state_machines-async is not available on #{RUBY_ENGINE}.

    The async gem requires native extensions (io-event) and Fiber scheduler
    support, which #{RUBY_ENGINE} does not implement. Async mode runs on CRuby
    (MRI) 4.0+ only; on #{RUBY_ENGINE}, use synchronous state machines.
  ERROR
end

require 'async'
require 'concurrent-ruby'
require 'state_machines'

# Load all async mode components
require_relative 'async_mode/thread_safe_state'
require_relative 'async_mode/async_events'
require_relative 'async_mode/async_event_extensions'
require_relative 'async_mode/async_machine'
require_relative 'async_mode/async_transition_collection'

module StateMachines
  # AsyncMode provides asynchronous state machine capabilities using the async gem
  # This module enables concurrent, thread-safe state operations for high-performance applications
  #
  # @example Basic usage
  #   class AutonomousDrone < StarfleetShip
  #     state_machine :teleporter_status, async: true do
  #       event :power_up do
  #         transition offline: :charging
  #       end
  #     end
  #   end
  #
  #   drone = AutonomousDrone.new
  #   Async do
  #     result = drone.fire_event_async(:power_up)  # => true
  #     task = drone.power_up_async!               # => Async::Task
  #   end
  #
  module AsyncMode
    # All components are loaded from separate files:
    # - ThreadSafeState: Mutex-based thread safety
    # - AsyncEvents: Async event firing methods
    # - AsyncEventExtensions: Event method generation
    # - AsyncMachine: Machine-level async capabilities
    # - AsyncTransitionCollection: Concurrent transition execution
  end
end
