module WorkerKiller
  module Killer
    class Passenger < ::WorkerKiller::Killer::Base

      attr_reader :passenger_config

      def initialize path: nil, **kwrags
        super
        @passenger_config = if path.nil? || path.empty?
          self.class.check_passenger_config(`which passenger-config`)
        else
          self.class.check_passenger_config!(path)
        end
      end

      def do_kill(sig, pid, alive_sec, **params)
        cmd = "#{passenger_config} detach-process #{pid}"
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

      def self.check_passenger_config path
        path.strip!
        help_str = `#{path} detach-process --help 2> /dev/null`
        return path if help_str['Remove an application process'] || help_str['Phusion Passenger']
      rescue StandardError => e
        nil
      end

      def self.check_passenger_config! path
        if (path = check_passenger_config(path))
          path
        else
          raise "Can't find passenger config at #{path.inspect}"
        end
      end

    end
  end
end

