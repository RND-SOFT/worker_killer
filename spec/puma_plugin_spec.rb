RSpec.describe WorkerKiller::PumaPlugin do
  subject(:plugin){ described_class.instance }
  let(:puma) { double }
  let(:runner){ double }
  let(:events) { double }
  let(:launcher){ double('@runner' => runner, 'events' => events) }
  let(:worker){ double('booted?' => true, 'term?' => false) }

  it {
    is_expected.to have_attributes(ipc_path: /puma_worker_.*socket/,
                                   killer:   ::WorkerKiller::Killer::Puma)
  }

  context 'Puma initialization' do
    it do
      expect(puma).to receive(:on_worker_boot)
      plugin.config(puma)
    end

    it do
      launcher.instance_variable_set('@runner', runner)

      expect(Socket).to receive(:unix_server_loop).with(/puma_worker_.*socket/).and_yield(StringIO.new('99'))
      expect(events).to receive(:on_booted).and_yield
      expect(runner).to receive(:worker_at).with(99).and_return(worker)
      expect(plugin).to receive(:find_worker).with(99).and_call_original
      expect(worker).to receive(:term!)

      plugin.start(launcher)
      plugin.thread.join
    end
  end
end

