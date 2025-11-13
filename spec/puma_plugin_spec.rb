RSpec.describe WorkerKiller::PumaPlugin do
  subject(:plugin){ described_class.instance }
  let(:dsl) { double }
  let(:runner){ double }
  let(:events) { double }
  let(:launcher){ double('@runner' => runner, 'events' => events, log_writer: double(log: nil)) }
  let(:worker){ double('booted?' => true, 'term?' => false) }

  it {
    is_expected.to have_attributes(ipc_path: /puma_worker_.*socket/,
                                   killer:   ::WorkerKiller::Killer::Puma)
  }


  context 'Puma initialization' do
    it 'expected to register CB' do
      expect(dsl).to receive(:before_worker_boot).and_yield(123)
      plugin.config(dsl)
    end

    it do
      expect(plugin).to receive(:set_logger!).and_call_original
      expect(events).to receive(:on_booted)
      plugin.start(launcher)
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

  context 'expect right signal order' do
    let(:config) do
      WorkerKiller::Configuration.new.tap do |c|
        c.quit_attempts = 2
        c.term_attempts = 2
      end
    end

    let(:killer){ ::WorkerKiller::Killer::Puma.new(puma_plugin: plugin, worker_num: 99) }
    let(:buffer) { StringIO.new }

    around do |example|
      prev = WorkerKiller.configuration
      WorkerKiller.configuration = config
      example.run
    ensure
      WorkerKiller.configuration = prev
     end


    it 'expect right signal order' do
      expect(Socket).to receive(:unix).with(/puma_worker_.*socket/).and_yield(buffer).exactly(3).times
      expect(Process).not_to receive(:kill)

      killer.kill(Time.now)
      expect(buffer.string.strip).to eq(99.to_s)

      1.times { killer.kill(Time.now) } # 1 QUIT
      2.times { killer.kill(Time.now) } # 1 TERM
      5.times { killer.kill(Time.now) } # 5 KILL
    end
  end

  
end

