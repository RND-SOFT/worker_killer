require 'securerandom'

RSpec.describe WorkerKiller::Middleware do
  let(:app){ double(call: {}) }
  let(:killer) { double }
  let(:reaction){ double }
  let(:anykey){ SecureRandom.hex(8) }

  describe 'Custom class' do
    let(:klass){ double }
    let(:options){ { killer: killer, klass: klass, reaction: reaction, anykey: anykey } }
    subject{ described_class.new(app, **options) }

    it 'is expected to be initialized' do
      expect(klass).to receive(:new).with(anykey: anykey).and_return(99)
      expect(subject.limiter).to eq(99)
      expect(subject.killer).to eq(killer)
    end
  end

  describe WorkerKiller::Middleware::RequestsLimiter do
    let(:options){ { killer: killer, min: 3, max: 3 } }
    subject{ described_class.new(app, **options) }

    it 'is expected to be initialized without reaction' do
      expect(WorkerKiller::CountLimiter).to receive(:new).with(min: 3, max: 3).and_call_original
      expect(subject.limiter).to be_an(WorkerKiller::CountLimiter)
      expect(subject.limiter.min).to eq(3)
      expect(subject.limiter.max).to eq(3)
      expect(killer).to receive(:kill).with(Time).twice

      4.times do
        subject.call({})
      end
    end

    it 'is expected to be initialized with reaction' do
      options[:reaction] = reaction

      expect(WorkerKiller::CountLimiter).to receive(:new).with(min: 3, max: 3).and_call_original
      expect(subject.limiter).to be_an(WorkerKiller::CountLimiter)
      expect(subject.limiter.min).to eq(3)
      expect(subject.limiter.max).to eq(3)
      expect(reaction).to receive(:call).with(subject.limiter, killer).twice

      4.times do
        subject.call({})
      end
    end
  end

  describe WorkerKiller::Middleware::OOMLimiter do
    let(:options){ { killer: killer, min: 2222, max: 2223 } }
    subject{ described_class.new(app, **options) }

    it 'is expected to be initialized without reaction' do
      expect(WorkerKiller::MemoryLimiter).to receive(:new).with(min: 2222, max: 2223).and_call_original
      expect(subject.limiter).to be_an(WorkerKiller::MemoryLimiter)
      expect(subject.limiter.min).to eq(2222)
      expect(subject.limiter.max).to eq(2223)
      expect(killer).to receive(:kill).with(subject.limiter.started_at).once
      expect(subject.limiter).to receive(:check).and_return(true)

      subject.call({})
    end

    it 'is expected to be initialized with reaction' do
      options[:reaction] = reaction
      expect(WorkerKiller::MemoryLimiter).to receive(:new).with(min: 2222, max: 2223).and_call_original
      expect(subject.limiter).to be_an(WorkerKiller::MemoryLimiter)
      expect(subject.limiter.min).to eq(2222)
      expect(subject.limiter.max).to eq(2223)
      expect(reaction).to receive(:call).with(subject.limiter, killer)
      expect(subject.limiter).to receive(:check).and_return(true)

      subject.call({})
    end
  end
end

