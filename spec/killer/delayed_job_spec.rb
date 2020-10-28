RSpec.describe WorkerKiller::Killer::DelayedJob do
  let(:config) do
    WorkerKiller::Configuration.new.tap do |c|
      c.quit_attempts = 2
      c.term_attempts = 2
    end
  end

  let(:killer){ described_class.new() }
  let(:dj){ double }

  describe '#kill' do
    context 'with use_quit TRUE' do
      around do |example|
        prev = WorkerKiller.configuration
        WorkerKiller.configuration = config
        example.run
      ensure
        WorkerKiller.configuration = prev
      end

      it 'expect right signal order' do
        expect(dj).to receive(:stop).exactly(4)
        expect(Process).to receive(:kill).with(:TERM, anything).exactly(1).times
        expect(Process).to receive(:kill).with(:KILL, anything).exactly(5).times

        2.times { killer.kill(Time.now, dj: dj) } # 1 QUIT
        2.times { killer.kill(Time.now, dj: dj) } # 1 TERM
        5.times { killer.kill(Time.now, dj: dj) } # 5 KILL
      end
    end
  end
end

