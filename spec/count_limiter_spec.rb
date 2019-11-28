RSpec.describe WorkerKiller::CountLimiter do
  let(:logger){ Logger.new(nil) }

  subject{ described_class.new(options) }
  let(:min){ rand(50..100) }
  let(:max){ min + rand(100) }
  let(:options){ { min: min, max: max } }

  it { is_expected.to have_attributes(min: min, max: max, limit: a_value_between(min, max), left: subject.limit) }

  it 'expect not to react while less than limit' do
    expect do |b|
      subject.reaction = b.to_proc
      (subject.limit - 1).times do
        expect(subject.check).to be_falsey
      end
    end.not_to yield_control
  end

  it 'expect call reaction when check succeded' do
    (subject.limit - 1).times do
      expect(subject.check).to be_falsey
    end

    expect do |b|
      subject.reaction = b.to_proc
      expect(subject.check).to be_truthy
      expect(subject.check).to be_truthy
    end.to yield_control.exactly(2).times
  end
end

