# StateMachines::Async

[![CI](https://github.com/state-machines/state_machines-async/actions/workflows/ruby.yml/badge.svg?branch=master)](https://github.com/state-machines/state_machines-async/actions/workflows/ruby.yml)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE.txt)

Async mode for [state_machines](https://github.com/state-machines/state_machines): state machines
whose events run as [async](https://github.com/socketry/async) tasks, with per-object
thread-safe state access (`concurrent-ruby`) and transitions claimed before they are performed, so
concurrent transitions out of one state perform once.

This gem owns async mode. The core `state_machines` gem ships none of it: without this gem loaded,
`state_machine ..., async: true` raises `ArgumentError` naming `state_machines-async`.

## Platform

CRuby (MRI) 4.0+ only. The async gem needs the Fiber scheduler and the io-event native extension,
which JRuby and TruffleRuby lack, so `require 'state_machines-async'` raises `LoadError` there
instead of running async machines synchronously.

## Installation

```ruby
gem 'state_machines-async'
```

```ruby
require 'state_machines-async'
```

## Usage

Enable async mode per machine with `async: true`; machines without it stay synchronous, and a
class can mix both:

```ruby
class AutonomousDrone
  state_machine :status, async: true, initial: :docked do
    event :launch do
      transition docked: :flying
    end

    event :land do
      transition flying: :docked
    end
  end

  # Synchronous machine on the same class
  state_machine :weapons, initial: :disarmed do
    event :arm do
      transition disarmed: :armed
    end
  end
end
```

An integration can make its machines async by default (`@defaults = { async: true }`); `async: false`
on a machine overrides that. `async:` is also accepted when reopening a machine (`state_machine :status, async: true`), and
`configure_async_mode!(enabled)` switches it from inside the machine definition.

### Async event methods

```ruby
drone = AutonomousDrone.new

Async do
  task = drone.launch_async     # => Async::Task
  task.wait                     # => #<StateMachines::Transition ...> or false

  drone.land_async!.wait        # raises StateMachines::InvalidTransition on failure

  drone.async_fire_event(:launch)          # => Async::Task
  drone.fire_events_concurrent(:land)      # => [result, ...]
end

# Waits for the result, entering a reactor if needed
drone.fire_event_async(:launch)            # => transition or false
drone.fire_event_async!(:land)             # raises on failure
drone.fire_events_async(:launch, :arm)     # => [result, result]

# Outside an Async context the task-returning methods raise
drone.launch_async # => RuntimeError: launch_async must be called within an Async context
```

### Concurrency

* Each object with an async machine gets its own `Concurrent::ReentrantReadWriteLock`, created on
  demand (`state_machine_mutex`, `read_state_safely`, `write_state_safely`). A `dup`/`clone` gets
  its own lock, and marshalling leaves the lock out.
* Async machines claim their transitions (`Machine#claims_transitions?`): of concurrent
  transitions out of one state, from threads or from fibers of one reactor, the first is
  performed and the others are refused with the `:contended` reason (see the core README's
  Refusal Reasons).
* `Machine#create_async_transition_collection` builds a collection with `perform_async` (in a
  reactor) and `perform_threaded`.

## Testing

`StateMachines::Async::TestHelper` includes the core's `StateMachines::TestHelper` and adds the
async assertions, so a test case includes only it:

```ruby
require 'state_machines/async/test_helper'

class DroneTest < Minitest::Test
  include StateMachines::Async::TestHelper

  def test_modes
    drone = AutonomousDrone.new

    assert_sm_async_mode(drone, :status)
    assert_sm_sync_mode(drone, :weapons)
    assert_sm_has_async(drone, %i[status])
    assert_sm_async_methods(drone)
    assert_sm_async_event_methods(drone, :launch)
    assert_sm_thread_safe_methods(drone)
  end
end
```

Also available: `assert_sm_all_sync`, `assert_sm_no_async_methods`.

## Development

```bash
bundle install
bundle exec rake test   # padded_cell
```

## License

MIT, see [LICENSE.txt](LICENSE.txt).
