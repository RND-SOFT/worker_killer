RSpec.describe WorkerKiller::Killer::Puma do
  let(:config) do
    WorkerKiller::Configuration.new.tap do |c|
      c.quit_attempts = 2
      c.term_attempts = 2
    end
  end

  let(:killer){ described_class.new }

  describe '#kill' do
    around do |example|
      prev = WorkerKiller.configuration
      WorkerKiller.configuration = config
      example.run
    ensure
      WorkerKiller.configuration = prev
    end

    it 'expect right signal order' do
      expect(Kernel).to receive(:system).with('pumactl phased-restart').and_return(true)
      expect(Process).to receive(:kill).with(:KILL, anything).exactly(5).times

      thread = killer.kill(Time.now)
      thread.join

      1.times { killer.kill(Time.now) } # 1 QUIT
      2.times { killer.kill(Time.now) } # 1 TERM
      5.times { killer.kill(Time.now) } # 5 KILL
    end
  end
end

