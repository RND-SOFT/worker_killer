RSpec.describe WorkerKiller::Killer::Base do
  let(:killer){ described_class.new }

  describe '#kill' do
    it 'expect right signal order' do
      if RUBY_VERSION >= '2.7.0'
        expect(killer).to receive(:do_kill).with(:QUIT, anything, anything).exactly(1).times
        expect(killer).to receive(:do_kill).with(:TERM, anything, anything).exactly(1).times
        expect(killer).to receive(:do_kill).with(:KILL, anything, anything).exactly(6).times
      else
        expect(killer).to receive(:do_kill).with(:QUIT, anything, anything,
                                                 anything).exactly(1).times
        expect(killer).to receive(:do_kill).with(:TERM, anything, anything,
                                                 anything).exactly(1).times
        expect(killer).to receive(:do_kill).with(:KILL, anything, anything,
                                                 anything).exactly(6).times
      end

      3.times { killer.kill(Time.now) } # 1 QUIT, 1 TERM, 1 KILL
      5.times { killer.kill(Time.now) } # 5 KILL
    end
  end
end

