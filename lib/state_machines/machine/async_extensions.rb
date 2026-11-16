# frozen_string_literal: true

module StateMachines
  class Machine
    # Async mode for the Machine class: the +async:+ option on creation and on
    # reopening, and the per-machine switch. Prepended, since it plugs into the
    # core's Machine#creation_options, #after_definition,
    # #claims_transitions?, #reopen_options and #reopen.
    module AsyncExtensions
      # A new machine also accepts +async:+.
      #
      #   class Vehicle
      #     state_machine initial: :parked, async: true do
      #       event :ignite do
      #         transition parked: :idling
      #       end
      #     end
      #   end
      def creation_options
        super + %i[async]
      end

      # Turns async mode on or off for this machine.
      #
      # Example:
      #   class Vehicle
      #     state_machine initial: :parked do
      #       configure_async_mode! # Enable async for this machine
      #
      #       event :ignite do
      #         transition parked: :idling
      #       end
      #     end
      #   end
      def configure_async_mode!(enabled = true)
        @async_mode_enabled = enabled ? true : false
        return self unless @async_mode_enabled

        owner_class.include(StateMachines::AsyncMode::ThreadSafeState)
        owner_class.include(StateMachines::AsyncMode::AsyncEvents)
        extend(StateMachines::AsyncMode::AsyncMachine)

        # Extend events to generate async versions
        events.each do |event|
          event.extend(StateMachines::AsyncMode::AsyncEventExtensions)
        end

        self
      end

      # Check if this specific machine instance has async mode enabled
      def async_mode_enabled?
        @async_mode_enabled || false
      end

      # An async machine's transitions run concurrently, so they are claimed
      # before they are performed. Another extension may claim them too.
      def claims_transitions?
        async_mode_enabled? || super
      end

      # A reopened machine also accepts +async:+.
      def reopen_options
        super + %i[async]
      end

      # Applies +async:+ when a machine is reopened.
      def reopen(options)
        super
        configure_async_mode!(options[:async]) if options.include?(:async)
      end

      # Thread-safe version of state reading
      def read_safely(object, attribute, ivar = false)
        object.read_state_safely(self, attribute, ivar)
      end

      # Thread-safe version of state writing
      def write_safely(object, attribute, value, ivar = false)
        object.write_state_safely(self, attribute, value, ivar)
      end

      # Thread-safe callback execution for async operations
      def run_callbacks_safely(type, object, context, transition)
        object.state_machine_mutex.with_write_lock do
          callbacks[type].each { |callback| callback.call(object, context, transition) }
        end
      end

      protected

      # Turns async mode on once the machine is defined, when +async:+ is
      # set: by the caller, or by the integration's defaults unless the
      # caller overrides them.
      def after_definition(options)
        super
        configure_async_mode!(true) if options[:async]
      end
    end

    prepend AsyncExtensions
  end
end
