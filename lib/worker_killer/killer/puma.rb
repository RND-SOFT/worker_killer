module ::WorkerKiller
  module Killer
    class Puma < ::WorkerKiller::Killer::Base

      attr_accessor :worker_num

      def initialize(puma_plugin:, worker_num: nil, **kwargs)
        super(**kwargs)
        @puma_plugin = puma_plugin
        @worker_num = worker_num
      end

      def do_kill(sig, pid, alive_sec, **_params)
        return if @worker_num.nil? # May be nil if Puma not in Cluster mode
        return if @already_sended == sig

        logger.warn "#{self.class} send [W#{worker_num}] to Puma Plugin (from pid: #{pid}) alive: #{alive_sec} sec (trial #{kill_attempts}) triggered by #{sig}"

        @already_sended = sig
        @puma_plugin.set_logger!(logger)

        @puma_plugin.request_restart_server(worker_num)
      end

      def do_inhibit(_path_info)
        @puma_plugin.set_logger!(logger)

        @puma_plugin.inhibit_restart(worker_num)
      end

      def do_release
        @puma_plugin.set_logger!(logger)

        @puma_plugin.release_restart(worker_num)
      end

    end
  end
end

