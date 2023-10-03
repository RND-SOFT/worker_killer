RSpec.describe WorkerKiller::DelayedJobPlugin::JobsLimiter do
  let(:killer) { double }
  subject(:plugin){ described_class.new(killer: killer) }

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

