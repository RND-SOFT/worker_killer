RSpec.describe WorkerKiller do
  let(:logger){ Logger.new(nil) }

  describe '#randomize' do
    [1, 5, 25, 125, 5000, 10_000].each do |max|
      it "randomize(#{max})" do
        1000.times do
          rnd = WorkerKiller.randomize(max)
          expect(rnd).to be >= 0
          expect(rnd).to be < max
        end
      end
    end
  end

end

