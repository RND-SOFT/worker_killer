RSpec.describe WorkerKiller::Killer::Signal do
  let(:logger){ Logger.new(nil) }
  let(:config) do
    WorkerKiller::Configuration.new.tap do |c|
      c.quit_attempts = 2
      c.term_attempts = 2
    end
  end

  let(:killer){ described_class.new(logger: logger) }

  describe '#kill' do
    context 'with use_quit TRUE' do
      around do |example|
        prev = WorkerKiller.configuration
        config.use_quit = true
        WorkerKiller.configuration = config
        example.run
      ensure
        WorkerKiller.configuration = prev
      end

      it 'expect right signal order' do
        expect(Process).to receive(:kill).with(:QUIT, anything).exactly(1).times
        expect(Process).to receive(:kill).with(:TERM, anything).exactly(1).times
        expect(Process).to receive(:kill).with(:KILL, anything).exactly(1).times

        2.times { killer.kill(Time.now) } # 1 QUIT
        2.times { killer.kill(Time.now) } # 1 TERM
        5.times { killer.kill(Time.now) } # 1 KILL
      end
    end
  end
end

