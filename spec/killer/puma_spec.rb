RSpec.describe WorkerKiller::Killer::Puma do
  let(:config) do
    WorkerKiller::Configuration.new.tap do |c|
      c.quit_attempts = 2
      c.term_attempts = 2
    end
  end

  let(:ipc_path) { '/tmp/test_ipx.sock' }
  let(:killer){ described_class.new(ipc_path: ipc_path, worker_num: 99) }
  let(:buffer) { StringIO.new }

  describe '#kill' do
    around do |example|
      prev = WorkerKiller.configuration
      WorkerKiller.configuration = config
      example.run
    ensure
      WorkerKiller.configuration = prev
    end

    it 'expect right signal order' do
      expect(Socket).to receive(:unix).with(ipc_path).and_yield(buffer).exactly(3).times
      expect(Process).not_to receive(:kill)

      killer.kill(Time.now)
      expect(buffer.string.strip).to eq(99.to_s)

      1.times { killer.kill(Time.now) } # 1 QUIT
      2.times { killer.kill(Time.now) } # 1 TERM
      5.times { killer.kill(Time.now) } # 5 KILL
    end
  end
end

