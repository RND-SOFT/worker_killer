require 'securerandom'

RSpec.describe WorkerKiller::Middleware do
  let(:logger){ Logger.new(nil) }

  let(:app){ double }
  let(:reaction){ ->{} }
  let(:anykey){ SecureRandom.hex(8) }

  describe 'Custom class' do
    let(:klass){ double }
    let(:options){ { klass: klass, reaction: reaction, anykey: anykey } }
    subject{ described_class.new(app, options) }

    it 'is expected to be initialized' do
      expect(klass).to receive(:new).with(anykey: anykey).and_return(99)
      expect(subject.limiter).to eq(99)
    end
  end

  describe WorkerKiller::Middleware::RequestsLimiter do
    let(:options){ {reaction: reaction, min: 1111 } }
    subject{ described_class.new(app, options) }

    it 'is expected to be initialized with reaction' do
      expect(WorkerKiller::CountLimiter).to receive(:new).with(min: 1111).and_call_original
      expect(subject.limiter).to be_an(WorkerKiller::CountLimiter)
      expect(subject.limiter.min).to eq(1111)
      expect(subject.limiter.reaction).to eq(reaction)
    end
  end

  describe WorkerKiller::Middleware::OOMLimiter do
    let(:options){ {reaction: reaction, min: 2222 } }
    subject{ described_class.new(app, options) }

    it 'is expected to be initialized with reaction' do
      expect(WorkerKiller::MemoryLimiter).to receive(:new).with(min: 2222).and_call_original
      expect(subject.limiter).to be_an(WorkerKiller::MemoryLimiter)
      expect(subject.limiter.min).to eq(2222)
      expect(subject.limiter.reaction).to eq(reaction)
    end
  end

end

