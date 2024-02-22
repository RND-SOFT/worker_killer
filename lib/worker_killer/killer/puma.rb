require 'socket'

module ::WorkerKiller
  module Killer
    class Puma < ::WorkerKiller::Killer::Base

      attr_accessor :type, :plugin_path, :num

      def initialize(type: :phased, path: nil, num: nil, **kwargs)
        super(**kwargs)
        @type = type
        @plugin_path = path
        @num = num
      end

      def do_kill(sig, pid, alive_sec, **params)
        if @type == :phased
          do_phased_kill(sig, pid, alive_sec, **params)
        elsif @type == :plugin
          do_plugin_kill(sig, pid, alive_sec, **params)
        end
      end

      def do_phased_kill(sig, pid, alive_sec, **_params)
        cmd = 'pumactl phased-restart'

        if sig == :KILL
          logger.error "#{self} force to kill self (pid: #{pid}) alive: #{alive_sec} sec (trial #{kill_attempts})"
          Process.kill sig, pid
          return
        end

        return if @already_detached

        logger.warn "#{self} run #{cmd.inspect} (pid: #{pid}) alive: #{alive_sec} sec (trial #{kill_attempts})"
        @already_detached = true

        Thread.new(cmd) do |command|
          unless Kernel.system(command)
            logger.warn "#{self} run #{command.inspect} failed: #{$?.inspect}"
          end
        end
      end

      def do_plugin_kill(sig, pid, alive_sec, **_params)
        if sig == :KILL
          logger.error "#{self} force to kill self (pid: #{pid}) alive: #{alive_sec} sec (trial #{kill_attempts})"
          Process.kill sig, pid
          return
        end

        logger.warn "#{self} send #{num} to Puma Plugin (pid: #{pid}) alive: #{alive_sec} sec (trial #{kill_attempts})"

        Socket.unix(plugin_path) do |sock|
          sock.puts num.to_s
        end
      end

    end
  end
end

