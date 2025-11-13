require 'delegate'
require 'singleton'
require 'socket'

require 'worker_killer/memory_limiter'
require 'worker_killer/count_limiter'

module WorkerKiller
  class PumaPlugin

    include Singleton

    class PumaLogWrapper < SimpleDelegator

      def info(msg)
        __getobj__.log(msg)
      end

      def warn(msg)
        __getobj__.log(msg)
      end

      def debug(msg)
        __getobj__.log("(DEBUG) #{msg}")
      end

    end

    attr_accessor :ipc_path, :killer, :thread

    def initialize
      @killer = ::WorkerKiller::Killer::Puma.new(worker_num: nil, puma_plugin: self)
      @worker_num = nil
      @debug = false

      @ipc_path = File.join('tmp', "puma_worker_killer_#{Process.pid}.socket")
    end

    # Этот метод зовётся при ИНИЦИАЛИЗАЦИИ плагина внути master-процесса, в самомо начале
    # тут можно выполнить конфигурацию чегоднибудь нужного
    def config(dsl)
      if %w[t 1].include?(ENV.fetch('WORKER_KILLER_DEBUG', 'false').to_s.downcase[0].to_s)
        @debug = true
      end

      cb = if dsl.respond_to?(:before_worker_boot)
        :before_worker_boot
      else
        :on_worker_boot
      end

      dsl.send(cb) do |num|
        @killer.worker_num = num
        @worker_num = num
        @tag = nil
        log "Set worker_num: #{num}"
      end
    end

    # Этот метод зовётся при ИНИЦИАЛИЗАЦИИ плагина внути master-процесса, контролирующего кластер Puma
    # псле форка данные сохранённые тут также доступны (например logger)
    def start(launcher)
      set_logger!(PumaLogWrapper.new(launcher.log_writer))

      log "Initializing IPC: #{@ipc_path}"
      @runner = launcher.instance_variable_get('@runner')

      cb = if launcher.events.respond_to?(:after_booted)
        :after_booted
      else
        :on_booted
      end

      launcher.events.send(cb) do
        @thread ||= start_ipc_listener
      end
    end

    def set_logger!(logger)
      @logger = logger
    end

    # Этот метод зовётся из Middleware внтури воркера
    def request_restart_server(worker_num)
      log("Equeue worker #{worker_num} for restarting...")
      Socket.unix(ipc_path) do |sock|
        sock.puts Integer(worker_num).to_s
      end
    end

    # Этот метод зовётся из Middleware внтури воркера
    def inhibit_restart(_worker_num)
      nil
    end

    # Этот метод зовётся из Middleware внтури воркера
    def release_restart(_worker_num)
      nil
    end

    def start_ipc_listener
      log "Start IPC listener on #{@ipc_path}"
      Thread.new do
        Socket.unix_server_loop(ipc_path) do |sock, *_args|
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
      if @logger
        @logger.warn("#{tag} #{msg}")
      else
        warn("[#{Process.pid}] #{tag} #{msg}")
      end
    end

    def tag
      @tag ||= "[#{self.class}] #{@worker_num.nil? ? '[M]' : "[W#{@worker_num}]"}"
    end

    def debug(msg)
      return unless @debug

      if @logger
        @logger.debug("#{tag} #{msg}")
      else
        warn("[#{Process.pid}] #{tag} (DEBUG) #{msg}")
      end
    end

  end
end

