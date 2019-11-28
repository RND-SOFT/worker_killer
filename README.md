# worker-killer

Kill any workers by memory and request counts or take custom reaction. Inspired by [unicorn-worker-killer](https://github.com/kzk/unicorn-worker-killer).

`worker-killer` gem provides automatic restart of Web-server based on 1) max number of requests, and 2) process memory size (RSS). This will greatly improves site's stability by avoiding unexpected memory exhaustion at the application nodes.

Features:

* generic middleware implementation
* custom reactin hook

Planned:

* DelayedJob support

# Install

No external process like `god` is required. Just install one gem: `worker-killer`.
```ruby
  gem 'worker-killer'
```

# Usage

Add these lines to your `config.ru` or `application.rb`. (These lines should be added above the `require ::File.expand_path('../config/environment',  __FILE__)` line.

```ruby
  # self-process killer
  require 'worker_killer/middleware'
  
  # Max requests per worker
  config.middleware.insert_before(Rack::Sendfile, WorkerKiller::Middleware::RequestsLimiter, min: 4096, max: 5120)
  
  # Max memory size (RSS) per worker
  config.middleware.insert_before(Rack::Sendfile, WorkerKiller::Middleware::OOMLimiter, min: 300 * (1024**2), max: 400 * (1024**2))
```

This gem provides two modules: WorkerKiller::CountLimiter and WorkerKiller::MemoryLimiter and some Rack integration.

### `WorkerKiller::Middleware::RequestsLimiter`

This module automatically restarts the kill workers, based on the number of requests which worker processed.

`min` and `max` specify the min and max of maximum requests per worker. The actual limit is decided by rand() between `min` and `max` per worker, to prevent all workers to be dead at the same time. Once the number exceeds the limit, that worker is automatically restarted.

If `verbose` is set to true, then after every request, your log will show the requests left before restart.  This logging is done at the `info` level.

### `WorkerKiller::Middleware::OOMLimiter`

This module automatically restarts the Unicorn workers, based on its memory size.

`min` and `max` specify the min and max of maximum memory in bytes per worker. The actual limit is decided by rand() between `min` and `max` per worker, to prevent all workers to be dead at the same time.  Once the memory size exceeds `memory_size`, that worker is automatically restarted.

The memory size check is done in every `check_cycle` requests.

If `verbose` is set to true, then every memory size check will be shown in your logs.   This logging is done at the `info` level.

# Special Thanks

- [@hotchpotch](http://github.com/hotchpotch/) for the [original idea](https://gist.github.com/hotchpotch/1258681)
- [@kzk](http://github.com/kzk/) for the [unicorn-worker-killer](https://github.com/kzk/unicorn-worker-killer)

