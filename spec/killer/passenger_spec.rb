RSpec.describe WorkerKiller::Killer::Passenger do
  let(:logger){ Logger.new(nil) }
  let(:config) do
    WorkerKiller::Configuration.new.tap do |c|
      c.quit_attempts = 2
      c.term_attempts = 2
    end
  end

  let(:killer){ described_class.new(logger: logger) }

  describe '#kill' do
    before do
      allow(described_class).to receive(:check_passenger_config).and_return('custompath')
    end

    around do |example|
      prev = WorkerKiller.configuration
      WorkerKiller.configuration = config
      example.run
    ensure
      WorkerKiller.configuration = prev
    end

    it 'expect right signal order' do
      expect(Kernel).to receive(:system).with("custompath detach-process #{Process.pid}").and_return(true)
      expect(Process).to receive(:kill).with(:KILL, anything).exactly(5).times

      thread = killer.kill(Time.now)
      thread.join

      1.times { killer.kill(Time.now) } # 1 QUIT
      2.times { killer.kill(Time.now) } # 1 TERM
      5.times { killer.kill(Time.now) } # 5 KILL
    end
  end

  describe '#check_passenger_config!' do
    it do
      expect{ described_class.check_passenger_config!('nonenone') }.to raise_error(/Can't find passenger/)
    end
  end
end

