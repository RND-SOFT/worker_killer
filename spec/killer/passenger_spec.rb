RSpec.describe WorkerKiller::Killer::Passenger do
  let(:killer){ described_class.new }

  describe '#kill' do
    before do
      allow(described_class).to receive(:check_passenger_config).and_return('custompath')
    end

    it 'expect right signal order' do
      expect(Kernel).to receive(:system).with("custompath detach-process #{Process.pid}").and_return(true)
      expect(Process).to receive(:kill).with(:KILL, anything).exactly(6).times

      3.times { killer.kill(Time.now) } # 1 QUIT 1 TERM 1 KILL
      5.times { killer.kill(Time.now) } # 5 KILL
    end
  end

  describe '#check_passenger_config!' do
    it do
      expect do
        described_class.check_passenger_config!('nonenone')
      end.to raise_error(/Can't find passenger/)
    end
  end
end

