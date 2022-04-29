RSpec.describe WorkerKiller::MemoryLimiter do
  let(:logger){ Logger.new(nil) }

  subject{ described_class.new(**options) }
  let(:mb){ 1024 * 1024 }
  let(:min){ rand(50..100) * mb }
  let(:max){ min + rand(100) * mb }
  let(:check_cycle){ 5 }
  let(:options){ { min: min, max: max, check_cycle: check_cycle, verbose: true} }

  it { is_expected.to have_attributes(min: min, max: max, limit: a_value_between(min, max)) }

  def skip_cycles(object, cycles)
    (cycles - 1).times do
      expect(object.check).to be_nil
    end
  end

  it 'expect to skip check while less than cycle count' do
    expect(GetProcessMem).not_to receive(:new)

    skip_cycles(subject, check_cycle)
  end

  it 'expect to skip check after cycle count reached' do
    memory = instance_double(GetProcessMem)
    expect(memory).to receive(:bytes).and_return(min - 1)
    expect(GetProcessMem).to receive(:new).and_return(memory)

    skip_cycles(subject, check_cycle)
    expect(subject.check).to be_falsey
  end

  it 'expect call reaction when check succeded' do
    memory = instance_double(GetProcessMem)
    expect(memory).to receive(:bytes).and_return(subject.limit + 1)
    expect(GetProcessMem).to receive(:new).and_return(memory)

    skip_cycles(subject, check_cycle)
    expect(subject.check).to be_truthy
  end
end

