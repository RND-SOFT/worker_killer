require 'singleton'

require 'worker_killer/memory_limiter'
require 'worker_killer/count_limiter'


module WorkerKiller
  class PumaPlugin

    include Singleton

    attr_accessor :ipc_path, :killer, :thread

    def initialize
      @ipc_path = File.join('tmp', "puma_worker_killer_#{Process.pid}.socket")
      @killer = ::WorkerKiller::Killer::Puma.new(worker_num: nil, ipc_path: ipc_path)
      log "Initializing IPC: #{@ipc_path}"
    end

    def config(puma)
      puma.on_worker_boot do |num|
        log "Set worker_num: #{num}"
        @killer.worker_num = num
      end
    end

    def start(launcher)
      @runner = launcher.instance_variable_get('@runner')

      launcher.events.on_booted do
        @thread ||= start_ipc_listener
      end
    end

    def start_ipc_listener
      log 'Start IPC listener'
      Thread.new do
        Socket.unix_server_loop(ipc_path) do |sock, *args|
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
      warn("#{self.class}[#{Process.pid}]: #{msg}")
    end

  end
end

