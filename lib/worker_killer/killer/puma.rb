require 'socket'

module ::WorkerKiller
  module Killer
    class Puma < ::WorkerKiller::Killer::Base

      attr_accessor :ipc_path, :worker_num

      def initialize(ipc_path:, worker_num: nil, **kwargs)
        super(**kwargs)
        @ipc_path = ipc_path
        @worker_num = worker_num
      end

      def do_kill(sig, pid, alive_sec, **_params)
        return if @already_sended == sig

        logger.warn "#{self} send #{worker_num} to Puma Plugin (pid: #{pid}) alive: #{alive_sec} sec (trial #{kill_attempts})"

        @already_sended = sig

        Socket.unix(ipc_path) do |sock|
          sock.puts Integer(worker_num).to_s
        end
      end

    end
  end
end

