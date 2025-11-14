RSpec.describe WorkerKiller::Killer::Puma do
  let(:puma_plugin) { double(set_logger!: nil) }
  let(:killer){ described_class.new(puma_plugin: puma_plugin, worker_num: 99) }

  describe '#kill' do
    it do
      expect(puma_plugin).to receive(:request_restart_server)

      killer.kill(Time.now)
    end
  end

end

