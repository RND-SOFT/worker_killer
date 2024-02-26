RSpec.describe WorkerKiller::MemoryLimiter do
  let(:logger){ Logger.new(nil) }

  subject{ described_class.new(**options) }
  let(:check_cycle){ 5 }
  let(:options){ { min: min, max: max, check_cycle: check_cycle, verbose: true } }
  let(:memory) { instance_double(GetProcessMem) }


  def skip_cycles(object, cycles)
    (cycles - 1).times do
      expect(object.check).to be_nil
    end
  end

  before do
    allow(GetProcessMem).to receive(:new).and_return(memory)
  end

  context 'fixed memory limit' do
    let(:mb){ 1024 * 1024 }
    let(:min){ rand(50..100) * mb }
    let(:max){ min + rand(100) * mb }

    it { is_expected.to have_attributes(min: min, max: max, limit: nil) }

    it 'expect to skip check while less than cycle count' do
      expect(GetProcessMem).not_to receive(:new)

      skip_cycles(subject, check_cycle)
    end

    it 'expect to initialize limits after cycle count' do
      expect(memory).to receive(:bytes).and_return(min)
      is_expected.to have_attributes(min: min, max: max, limit: nil)

      skip_cycles(subject, check_cycle)
      subject.check
      is_expected.to have_attributes(min: min, max: max, limit: a_value_between(min, max))
    end

    it 'expect to skip check after cycle count reached' do
      expect(memory).to receive(:bytes).and_return(min - 1)

      skip_cycles(subject, check_cycle)
      expect(subject.check).to be_falsey
    end

    it 'expect call reaction when check succeded' do
      expect(memory).to receive(:bytes).and_return(min)

      skip_cycles(subject, check_cycle)
      subject.check

      expect(memory).to receive(:bytes).and_return(subject.limit + 1)
      skip_cycles(subject, check_cycle)
      expect(subject.check).to be_truthy
    end
  end

  context 'relative memory limit' do
    let(:min){ nil }
    let(:max){ 0.5 }
    let(:rss) { 100 * 1024 * 1024 }
    let(:min_expected) { rss }
    let(:max_expected) { min_expected + min_expected * max }

    it { is_expected.to have_attributes(min: nil, max: nil, limit: nil) }

    it 'expect to initialize limits on first check' do
      expect(memory).to receive(:bytes).and_return(rss)

      skip_cycles(subject, check_cycle)
      is_expected.to have_attributes(min: nil, max: nil, limit: nil)

      expect(subject.check).to be_falsey

      is_expected.to have_attributes(min: min_expected, max: max_expected, limit: max_expected)
    end

    it 'expect call reaction when check succeded' do
      expect(memory).to receive(:bytes).and_return(rss)

      skip_cycles(subject, check_cycle)
      expect(subject.check).to be_falsey

      expect(memory).to receive(:bytes).and_return(subject.limit + 1)
      skip_cycles(subject, check_cycle)
      expect(subject.check).to be_truthy
    end
  end
end

