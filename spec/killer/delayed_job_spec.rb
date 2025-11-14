RSpec.describe WorkerKiller::Killer::DelayedJob do
  let(:dj){ double }
  subject(:killer){ described_class.new }

  describe '#kill' do
    it 'expect right signal order' do
      expect(dj).to receive(:stop).exactly(1)
      expect(Process).to receive(:kill).with(:TERM, anything).exactly(1).times
      expect(Process).to receive(:kill).with(:KILL, anything).exactly(6).times

      3.times { killer.kill(Time.now, dj: dj) } # 1 QUIT 1 TERM 1 KILL
      5.times { killer.kill(Time.now, dj: dj) } # 5 KILL
    end
  end
end

