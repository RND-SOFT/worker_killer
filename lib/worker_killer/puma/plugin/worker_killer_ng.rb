require 'worker_killer'
require 'worker_killer/puma_plugin_ng'

Puma::Plugin.create do
  def config(cfg)
    ::WorkerKiller::PumaPluginNg.instance.config(cfg)
  end

  def start(launcher)
    ::WorkerKiller::PumaPluginNg.instance.start(launcher)
  end
end

