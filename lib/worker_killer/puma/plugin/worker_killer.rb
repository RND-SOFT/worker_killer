require 'worker_killer'
require 'worker_killer/puma_plugin'

Puma::Plugin.create do
  def config(cfg)
    ::WorkerKiller::PumaPlugin.instance.config(cfg)
  end

  def start(launcher)
    ::WorkerKiller::PumaPlugin.instance.start(launcher)
  end
end

