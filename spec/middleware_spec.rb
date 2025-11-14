require 'securerandom'

RSpec.describe WorkerKiller::Middleware do
  let(:rack_body) { double(each: %w[1 2 3], close: true) }
  let(:app){ double(call: [nil, nil, rack_body]) }
  let(:killer) { double(WorkerKiller::Killer::Base, do_inhibit: true) }
  let(:reaction){ double }
  let(:anykey){ SecureRandom.hex(8) }
  let(:inhibitions) { [%r{/attachments}] }
  let(:env) { { 'PATH_INFO' => '/something' } }

  describe 'Custom class' do
    let(:limiter_klass){ double }
    let(:options) do
      { killer: killer, klass: limiter_klass, reaction: reaction, anykey: anykey,
inhibitions: inhibitions }
    end
    subject{ described_class.new(app, **options) }

    it 'is expected to be initialized' do
      expect(limiter_klass).to receive(:new).with(anykey: anykey).and_return(99)
      expect(subject.limiter).to eq(99)
      expect(subject.killer).to eq(killer)
    end
  end

  describe WorkerKiller::Middleware::RequestsLimiter do
    let(:options){ { killer: killer, min: 3, max: 3, inhibitions: inhibitions } }
    subject{ described_class.new(app, **options) }

    it 'is expected to be initialized without reaction' do
      expect(WorkerKiller::CountLimiter).to receive(:new).with(min: 3, max: 3).and_call_original
      expect(subject.limiter).to be_an(WorkerKiller::CountLimiter)
      expect(subject.limiter.min).to eq(3)
      expect(subject.limiter.max).to eq(3)
      expect(killer).to receive(:kill).with(Time)

      4.times do
        subject.call(env)
      end
    end

    describe 'inhibitions' do
      let(:env) { { 'PATH_INFO' => '/attachments' } }

      it 'is expected to use inhibitions' do
        expect(WorkerKiller::CountLimiter).to receive(:new).with(min: 3, max: 3).and_call_original
        expect(subject.limiter).to be_an(WorkerKiller::CountLimiter)
        expect(subject.limiter.min).to eq(3)
        expect(subject.limiter.max).to eq(3)
        expect(killer).to receive(:kill).with(Time)
        expect(subject).to receive(:release).exactly(4).times.and_call_original

        4.times do
          expect(app).to receive(:call).and_return([nil, nil, rack_body])
          rack_response = subject.call(env)
          subject.react
          rack_response[2].each.to_a
        end
      end
    end

    it 'is expected to be initialized with reaction' do
      options[:reaction] = reaction

      expect(WorkerKiller::CountLimiter).to receive(:new).with(min: 3, max: 3).and_call_original
      expect(subject.limiter).to be_an(WorkerKiller::CountLimiter)
      expect(subject.limiter.min).to eq(3)
      expect(subject.limiter.max).to eq(3)
      expect(reaction).to receive(:call).with(subject.limiter, killer)

      4.times do
        subject.call(env)
      end
    end
  end

  describe WorkerKiller::Middleware::OOMLimiter do
    let(:options){ { killer: killer, min: 2222, max: 2223, inhibitions: inhibitions } }
    subject{ described_class.new(app, **options) }

    it 'is expected to be initialized without reaction' do
      expect(WorkerKiller::MemoryLimiter).to receive(:new).with(min: 2222,
                                                                max: 2223).and_call_original
      expect(subject.limiter).to be_an(WorkerKiller::MemoryLimiter)
      expect(subject.limiter.min).to eq(2222)
      expect(subject.limiter.max).to eq(2223)
      expect(killer).to receive(:kill).with(subject.limiter.started_at).once
      expect(subject.limiter).to receive(:check).and_return(true)

      subject.call(env)
    end

    it 'is expected to be initialized with reaction' do
      options[:reaction] = reaction
      expect(WorkerKiller::MemoryLimiter).to receive(:new).with(min: 2222,
                                                                max: 2223).and_call_original
      expect(subject.limiter).to be_an(WorkerKiller::MemoryLimiter)
      expect(subject.limiter.min).to eq(2222)
      expect(subject.limiter.max).to eq(2223)
      expect(reaction).to receive(:call).with(subject.limiter, killer)
      expect(subject.limiter).to receive(:check).and_return(true)

      subject.call(env)
    end
  end
end

