require 'delegate'
require 'singleton'

require 'worker_killer/memory_limiter'
require 'worker_killer/count_limiter'


module WorkerKiller
  class PumaPluginNg

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

    attr_accessor :killer, :puma_server, :inhibited, :kill_queue

    def initialize
      @killer = ::WorkerKiller::Killer::Puma.new(worker_num: nil, puma_plugin: self)
      @worker_num = nil
      @debug = false

      @puma_server = nil

      @force_restart = false
      @inhibited ||= Hash.new {|h, k| h[k] = 0 }
      @kill_queue ||= Set.new
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

      dsl.out_of_band do
        do_kill('OOB') unless @force_restart
      end
    end

    # Этот метод зовётся при ИНИЦИАЛИЗАЦИИ плагина внути master-процесса, контролирующего кластер Puma
    # псле форка данные сохранённые тут также доступны (например logger)
    def start(launcher)
      set_logger!(PumaLogWrapper.new(launcher.log_writer))
    end

    def set_logger!(logger)
      @logger = logger
    end

    # Завершать процесс сразу после окончания inhibited метода. Иначе завершение будет происзодть в Out Of Band методе
    def force_restart!(force = true)
      @force_restart = force
    end

    # Этот метод зовётся из Middleware внтури воркера
    def request_restart_server(worker_num)
      return if @worker_num != worker_num

      log("Equeue worker #{worker_num} for restarting...")
      kill_queue << worker_num
    end

    # Этот метод зовётся из Middleware внтури воркера
    def inhibit_restart(worker_num)
      return if @worker_num != worker_num

      cnt = inhibited[worker_num] += 1 # just increase inhibit counter
      debug("Worker inhibition increased: #{cnt}")
    end

    # Этот метод зовётся из Middleware внтури воркера
    def release_restart(worker_num)
      return if @worker_num != worker_num

      cnt = inhibited[worker_num] -= 1 # just decrease inhibit counter
      debug("Worker inhibition decreased: #{cnt}")
      return unless cnt <= 0

      inhibited.delete(worker_num)
      debug('Worker released')
      do_kill('RELEASE') if @force_restart
    end

    def do_kill(name)
      return if kill_queue.empty?

      log "Killing workers by #{name}: #{kill_queue}"
      (kill_queue - inhibited.keys).each do |worker_num|
        kill_queue.delete(worker_num)
        Thread.current.puma_server.begin_restart
      end
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

