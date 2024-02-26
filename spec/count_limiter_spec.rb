RSpec.describe WorkerKiller::CountLimiter do
  subject{ described_class.new(**options) }
  let(:min){ rand(50..100) }
  let(:max){ min + rand(100) }
  let(:options){ { min: min, max: max, verbose: true } }

  it { is_expected.to have_attributes(min: min, max: max, limit: nil, left: nil) }

  context 'initialize limits after first check' do
    before { subject.check }

    it {
      is_expected.to have_attributes(min: min, max: max,
                                     limit: a_value_between(min, max), left: subject.limit - 1)
    }

    it 'expect not to react while less than limit' do
      (subject.limit - 2).times do
        expect(subject.check).to be_falsey
      end
    end

    it 'expect call reaction when check succeded' do
      (subject.limit - 2).times do
        expect(subject.check).to be_falsey
      end

      expect(subject.check).to be_truthy
      expect(subject.check).to be_truthy
    end
  end
end

