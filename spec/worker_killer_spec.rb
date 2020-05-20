RSpec.describe WorkerKiller do
  let(:logger){ Logger.new(nil) }
  let(:config) do
    WorkerKiller::Configuration.new.tap do |c|
      c.quit_attempts = 2
      c.kill_attempts = 2
    end
  end

  before do
    WorkerKiller.instance_variable_set('@kill_attempts', nil)
  end

  describe '#randomize' do
    [1, 5, 25, 125, 5000, 10_000].each do |max|
      it "randomize(#{max})" do
        1000.times do
          rnd = WorkerKiller.randomize(max)
          expect(rnd).to be >= 0
          expect(rnd).to be < max
        end
      end
    end
  end

  describe '#kill_by_signal' do
    [:QUIT, :TERM, :KILL].each do |sig|
      it "must send #{sig} signal" do
        pid = rand(1000)
        expect(Process).to receive(:kill).with(sig, pid)
        WorkerKiller.kill_by_signal(logger, 11111, sig, pid)
      end
    end
  end

  describe '#kill_by_passenger' do
    it "must run passenger-config" do
      pid = rand(1000)
      path = "passenger-config-#{rand(1000)}"
      expect(Kernel).to receive(:system).with("#{path} detach-process #{pid}").and_return(true)

      thread = WorkerKiller.kill_by_passenger(logger, 11111, path, pid)
      thread.join
    end
  end

  describe '#kill_self' do
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
        expect(WorkerKiller).to receive(:kill_by_signal).with(logger, anything, :QUIT, anything).exactly(2).times
        expect(WorkerKiller).to receive(:kill_by_signal).with(logger, anything, :TERM, anything).exactly(2).times
        expect(WorkerKiller).to receive(:kill_by_signal).with(logger, anything, :KILL, anything).exactly(5).times

        2.times { WorkerKiller.kill_self(logger, Time.now) } # 2 QUIT
        2.times { WorkerKiller.kill_self(logger, Time.now) } # 2 TERM
        5.times { WorkerKiller.kill_self(logger, Time.now) } # other - KILL
      end
    end

    context 'with use_quit FALSE' do
      around do |example|
        prev = WorkerKiller.configuration
        config.use_quit = false
        WorkerKiller.configuration = config
        example.run
      ensure
        WorkerKiller.configuration = prev
      end

      it 'expect right signal order' do
        expect(WorkerKiller).to receive(:kill_by_signal).with(logger, anything, :TERM, anything).exactly(2).times
        expect(WorkerKiller).to receive(:kill_by_signal).with(logger, anything, :KILL, anything).exactly(5).times

        2.times { WorkerKiller.kill_self(logger, Time.now) } # 2 TERM
        5.times { WorkerKiller.kill_self(logger, Time.now) } # other - KILL
      end
    end
  end
end

