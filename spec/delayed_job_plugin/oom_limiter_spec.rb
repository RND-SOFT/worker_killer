RSpec.describe WorkerKiller::DelayedJobPlugin::OOMLimiter do
  let(:killer) { double }
  subject(:plugin){ described_class.new(min: (1024**3), max: (2 * (1024**3)), killer: killer) }

  context 'DelayedJob initialization' do
    let(:lifecycle) { double }
    subject(:instance) { plugin.new(lifecycle) }

    it do
      expect(lifecycle).to receive(:after).with(:perform).and_yield
      expect(lifecycle).to receive(:after).with(:loop).and_yield
      instance
    end
  end
end

