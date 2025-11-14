RSpec.describe WorkerKiller::Killer::Signal do
  let(:killer){ described_class.new }

  describe '#kill' do
    it 'expect right signal order' do
      expect(Process).to receive(:kill).with(:QUIT, anything).exactly(1).times
      expect(Process).to receive(:kill).with(:TERM, anything).exactly(1).times
      expect(Process).to receive(:kill).with(:KILL, anything).exactly(1).times

      3.times { killer.kill(Time.now) } # 1 QUIT 1 TERM 1 KILL
      5.times { killer.kill(Time.now) } # nothing
    end
  end
end

