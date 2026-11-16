# frozen_string_literal: true

module StateMachines
  module AsyncMode
    # Thread-safe state operations for async-enabled state machines
    # Uses concurrent-ruby for enterprise-grade thread safety
    module ThreadSafeState
      # The core's per-object concurrency state, plus the lock
      TRANSIENT_VARIABLES = (StateMachines::InstanceMethods::TRANSIENT_VARIABLES + %i[@_state_machine_mutex]).freeze

      MUTEX_CREATION_LOCK = Thread::Mutex.new

      # Gets or creates a reentrant mutex for thread-safe state operations on an object
      # Each object gets its own mutex to avoid global locking
      # Uses Concurrent::ReentrantReadWriteLock for better performance
      def state_machine_mutex
        @_state_machine_mutex || MUTEX_CREATION_LOCK.synchronize do
          @_state_machine_mutex ||= Concurrent::ReentrantReadWriteLock.new
        end
      end

      # Thread-safe version of state reading
      # Ensures atomic read operations across concurrent threads
      def read_state_safely(machine, attribute, ivar = false)
        state_machine_mutex.with_read_lock do
          machine.read(self, attribute, ivar)
        end
      end

      # Thread-safe version of state writing
      # Ensures atomic write operations across concurrent threads
      def write_state_safely(machine, attribute, value, ivar = false)
        state_machine_mutex.with_write_lock do
          machine.write(self, attribute, value, ivar)
        end
      end

      # A copy (+dup+ / +clone+) gets its own lock (created on demand) instead
      # of sharing the original's.
      #
      # A class defining its own +initialize_copy+ must call +super+.
      def initialize_copy(orig)
        super
        remove_instance_variable(:@_state_machine_mutex) if instance_variable_defined?(:@_state_machine_mutex)
      end

      # Handle marshalling by excluding the mutex (will be recreated when needed)
      def marshal_dump
        vars = instance_variables - TRANSIENT_VARIABLES
        vars.map { |var| [var, instance_variable_get(var)] }
      end

      # Restore marshalled object, mutex will be lazily recreated when needed
      def marshal_load(data)
        data.each do |var, value|
          instance_variable_set(var, value)
        end
      end
    end
  end
end
