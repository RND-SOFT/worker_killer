require "puma/thread_pool"

RSpec.describe WorkerKiller::PumaPluginNg do
  subject(:plugin){ described_class.send(:new) }
  let(:dsl) { double }
  let(:runner){ double }
  let(:events) { double }
  let(:launcher){ double('@runner' => runner, 'events' => events, log_writer: double(log: nil)) }
  let(:worker){ double('booted?' => true, 'term?' => false) }

  it {
    is_expected.to have_attributes(killer:     ::WorkerKiller::Killer::Puma,
                                   inhibited:  Hash,
                                   kill_queue: Set)
  }

  context 'Puma initialization' do
    it 'expected to register CB' do
      expect(dsl).to receive(:before_worker_boot).and_yield(123)
      expect(dsl).to receive(:out_of_band).and_yield
      plugin.config(dsl)
    end

    it do
      expect(plugin).to receive(:set_logger!).and_call_original
      plugin.start(launcher)
    end
  end

  context '#request_restart_server' do
    it do
      plugin.instance_variable_set('@worker_num', 99)
      expect { plugin.request_restart_server(99) }.to change { plugin.kill_queue }.to([99])
    end
  end

  context '#inhibit_restart' do
    it do
      plugin.instance_variable_set('@worker_num', 99)
      expect { plugin.inhibit_restart(99) }.to change { plugin.inhibited }.from({}).to({ 99 => 1 })
    end
  end

  context '#release_restart' do
    it do
      plugin.instance_variable_set('@worker_num', 99)
      plugin.inhibit_restart(99)

      expect { plugin.release_restart(99) }.to change { plugin.inhibited }.from({ 99 => 1 }).to({})
    end
  end

  context '#do_kill' do
    it do
      plugin.instance_variable_set('@worker_num', 99)
      plugin.request_restart_server(99)
      puma_server = double()
      Thread.current.puma_server = puma_server
      expect(puma_server).to receive(:begin_restart)

      plugin.do_kill('test')
    end
  end
end

