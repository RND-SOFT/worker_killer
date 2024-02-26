# worker-killer

[![Gem Version](https://badge.fury.io/rb/worker_killer.svg)](https://rubygems.org/gems/worker_killer)
[![Gem](https://img.shields.io/gem/dt/worker_killer.svg)](https://rubygems.org/gems/worker_killer/versions)
[![YARD](https://badgen.net/badge/YARD/doc/blue)](http://www.rubydoc.info/gems/worker_killer)

[![Coverage](https://lysander.rnds.pro/api/v1/badges/wkiller_coverage.svg)](https://lysander.rnds.pro/api/v1/badges/wkiller_coverage.html)
[![Quality](https://lysander.rnds.pro/api/v1/badges/wkiller_quality.svg)](https://lysander.rnds.pro/api/v1/badges/wkiller_quality.html)
[![Outdated](https://lysander.rnds.pro/api/v1/badges/wkiller_outdated.svg)](https://lysander.rnds.pro/api/v1/badges/wkiller_outdated.html)
[![Vulnerabilities](https://lysander.rnds.pro/api/v1/badges/wkiller_vulnerable.svg)](https://lysander.rnds.pro/api/v1/badges/wkiller_vulnerable.html)

Kill any workers by memory and/or request counts or take custom reaction. Inspired by [unicorn-worker-killer](https://github.com/kzk/unicorn-worker-killer).

`worker-killer` gem provides automatic restart of Web-server and/or background job processor based on 1) max number of requests, and 2) process memory size (RSS). This will greatly improves site's stability by avoiding unexpected memory exhaustion at the application nodes.

Features:

- generic middleware implementation
- Phusion Passenger support(through `passenger-config detach-process <PID>`)
- Puma support through native plugin
- DelayedJob support
- custom reaction hook

# Install

No external process like `god` is required. Just install one gem: `worker-killer`.

```ruby
  gem 'worker-killer'
```

# Usage

## Rack-based Web-server

Add these lines to your `config.ru` or `application.rb`. (These lines should be added above the `require ::File.expand_path('../config/environment', __FILE__)` line.

```ruby
  # self-process killer
  require 'worker_killer/middleware'

  killer = WorkerKiller::Killer::Passenger.new

  # Max requests per worker
  middleware.insert_before(
    Rack::Runtime,
    WorkerKiller::Middleware::RequestsLimiter, killer: killer, min: 3072, max: 4096
  )

  # Max memory size (RSS) per worker
  middleware.insert_before(
    Rack::Runtime,
    WorkerKiller::Middleware::OOMLimiter, killer: killer, min: nil, max: 0.5, check_cycle: 16
  )
```

## DelayedJob background processor

Add these lines to your `initializers/delayed_job.rb` or `application.rb`.

```ruby
  # self-process killer
  require 'worker_killer/delayed_job_plugin'

  Delayed::Worker.plugins.tap do |plugins|
    killer = WorkerKiller::Killer::DelayedJob.new

    plugins << WorkerKiller::DelayedJobPlugin::JobsLimiter.new(
      killer: killer, min: 200, max: 300
    )

    plugins << WorkerKiller::DelayedJobPlugin::OOMLimiter.new(
      killer: killer, min: 500 * (1024**2), max: 600 * (1024**2)
    )
  end
```

## Puma Web-server

Add these lines to your `puma.rb` AND `application.rb`.

```ruby
  # puma.rb

  require 'worker_killer/puma/plugin/worker_killer'
  plugin('worker_killer')

  # application.rb
  if defined?(::Puma::Client)
    killer = ::WorkerKiller::PumaPlugin.instance.killer

    config.middleware.insert_before(
      Rack::Runtime,
      WorkerKiller::Middleware::OOMLimiter, killer: killer, min: nil, max: 0.5, verbose: false, check_cycle: 16
    )

    config.middleware.insert_before(
      Rack::Runtime,
      WorkerKiller::Middleware::RequestsLimiter, killer: killer, min: 3000, max: 4000, verbose: false
    )
  end
```

This gem provides two modules: WorkerKiller::CountLimiter and WorkerKiller::MemoryLimiter, some Rack integration, DelayedJob plugin and Puma plugin.

### WorkerKiller::Middleware::RequestsLimiter and WorkerKiller::DelayedJobPlugin::JobsLimiter

This module automatically restarts/kills the workers, based on the number of requests/jobs which worker processed.

`min` and `max` specify the min and max of maximum requests per worker. The actual limit is decided by rand() between `min` and `max` per worker, to prevent all workers to be dead at the same time. Once the number exceeds the limit, that worker is automatically restarted.

If `verbose` is set to true, then after every request, your log will show the requests left before restart. This logging is done at the `info` level.

### WorkerKiller::Middleware::OOMLimiter and WorkerKiller::DelayedJobPlugin::OOMLimiter

This module automatically restarts/kills the workers, based on its memory size.

`min` and `max` specify the min and max of maximum memory in bytes per worker. The actual limit is decided by rand() between `min` and `max` per worker, to prevent all workers to be dead at the same time. Once the memory size exceeds `memory_size`, that worker is automatically restarted.

The memory size check is done in every `check_cycle` requests.

If `verbose` is set to true, then every memory size check will be shown in your logs. This logging is done at the `info` level.

### WorkerKiller::PumaPlugin

Works in Puma `Cluster Mode`. Work correctly with `phased-restart` and `fork_workers`, but has maximum effectivity (memory usage) in simple `Cluster Mode` with **preload_app!**.

Example production config: 

```ruby
  port ENV.fetch('PUMA_PORT', 3000).to_i

  environment ENV.fetch('RAILS_ENV', 'development')

  pidfile ENV.fetch('PUMA_PIDFILE', 'tmp/pids/server.pid')

  threads ENV.fetch('PUMA_THREADS', 4).to_i

  workers ENV.fetch('PUMA_WORKERS', 3).to_i

  require 'worker_killer/puma/plugin/worker_killer'
  plugin('worker_killer')

  preload_app!
```

# Special Thanks

- [@hotchpotch](http://github.com/hotchpotch/) for the [original idea](https://gist.github.com/hotchpotch/1258681)
- [@kzk](http://github.com/kzk/) for the [unicorn-worker-killer](https://github.com/kzk/unicorn-worker-killer)
