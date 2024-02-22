require 'socket'
require 'puma/plugin'
require 'active_support/notifications'

require 'worker_killer/killer'




module WorkerKiller
  module Puma
    module Plugin
      # Puma requires such plugin name and path :(
      class WorkerKiller

        def initialize(launcher, path)
          @runner = launcher.instance_variable_get('@runner')

          @thread = Thread.new do
            Socket.unix_server_loop(path) do |sock, _client_addrinfo|
              if (line = sock.gets)
                worker_num = Integer(line.strip)
                if (worker = find_worker(worker_num))
                  log "Killing worker #{worker_num}"
                  worker.term!
                end
              end
            rescue StandardError => e
              log("Exception: #{e.inspect}")
            ensure
              sock.close
            end
          end
        end

        def find_worker(worker_num)
          worker = @runner.worker_at(worker_num)
          unless worker
            log "Unknown worker index: #{worker_num.inspect}. Skipping."
            return nil
          end

          unless worker.booted?
            log "Worker #{worker_num.inspect} is not booted yet. Skipping."
            return nil
          end

          if worker.term?
            log "Worker #{worker_num.inspect} already terminating. Skipping."
            return nil
          end

          worker
        end

        def log(msg)
          warn("#{self.class}: #{msg}")
        end

      end
    end
  end
end

Puma::Plugin.create do
  attr_reader :path

  def config(c)
    c.on_worker_boot do |num|

      if @killer
        puts "ON OTHER WORKER BOOT: #{num}"
        @killer.num = num
      else
        puts "ON MAIN WORKER BOOT: #{num}"
        ::ActiveSupport::Notifications.subscribe 'worker_killer.initialize' do |*eargs|
          @killer = ::WorkerKiller::Killer::Puma.new(num: num, path: path, type: :plugin)
          puts "ON WORKER BOOT INIT:#{num}"
          event = ActiveSupport::Notifications::Event.new(*eargs)
          config = event.payload[:config]

          @register_killer&.call(self, config, @killer)
        end
      end
    end
  end

  def start(launcher)
    @path = File.join('tmp', "puma_worker_killer_#{Process.pid}.socket")

    launcher.events.on_booted do
      @controller ||= WorkerKiller::Puma::Plugin::WorkerKiller.new(launcher, path)
    end
  end

  def configure(&block)
    self.instance_eval(&block)
  end

  def register_killer(&block)
    @register_killer = block
  end
end

