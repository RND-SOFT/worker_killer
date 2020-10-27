require 'securerandom'

RSpec.describe WorkerKiller::Middleware do
  let(:logger){ Logger.new(nil) }

  let(:app){ double }
  let(:killer) { double }
  let(:reaction){ double }
  let(:anykey){ SecureRandom.hex(8) }

  describe 'Custom class' do
    let(:klass){ double }
    let(:options){ { killer: killer, klass: klass, reaction: reaction, anykey: anykey } }
    subject{ described_class.new(app, options) }

    it 'is expected to be initialized' do
      expect(klass).to receive(:new).with(anykey: anykey).and_return(99)
      expect(subject.limiter).to eq(99)
      expect(subject.killer).to eq(killer)
    end
  end

  describe WorkerKiller::Middleware::RequestsLimiter do
    let(:options){ { killer: killer, min: 1111 } }
    subject{ described_class.new(app, options) }

    it 'is expected to be initialized without reaction' do
      expect(WorkerKiller::CountLimiter).to receive(:new).with(min: 1111).and_call_original
      expect(subject.limiter).to be_an(WorkerKiller::CountLimiter)
      expect(subject.limiter.min).to eq(1111)
      expect(killer).to receive(:kill).with(subject.limiter.started_at)
      subject.limiter.reaction.call(subject.limiter)
    end

    it 'is expected to be initialized with reaction' do
      options[:reaction] = reaction
      expect(WorkerKiller::CountLimiter).to receive(:new).with(min: 1111).and_call_original
      expect(subject.limiter).to be_an(WorkerKiller::CountLimiter)
      expect(subject.limiter.min).to eq(1111)
      expect(reaction).to receive(:call).with(subject.limiter, killer)
      subject.limiter.reaction.call(subject.limiter)
    end
  end

  describe WorkerKiller::Middleware::OOMLimiter do
    let(:options){ { killer: killer, min: 2222 } }
    subject{ described_class.new(app, options) }

    it 'is expected to be initialized without reaction' do
      expect(WorkerKiller::MemoryLimiter).to receive(:new).with(min: 2222).and_call_original
      expect(subject.limiter).to be_an(WorkerKiller::MemoryLimiter)
      expect(subject.limiter.min).to eq(2222)
      expect(killer).to receive(:kill).with(subject.limiter.started_at)
      subject.limiter.reaction.call(subject.limiter)
    end

    it 'is expected to be initialized with reaction' do
      options[:reaction] = reaction
      expect(WorkerKiller::MemoryLimiter).to receive(:new).with(min: 2222).and_call_original
      expect(subject.limiter).to be_an(WorkerKiller::MemoryLimiter)
      expect(subject.limiter.min).to eq(2222)
      expect(reaction).to receive(:call).with(subject.limiter, killer)
      subject.limiter.reaction.call(subject.limiter)
    end
  end
end

