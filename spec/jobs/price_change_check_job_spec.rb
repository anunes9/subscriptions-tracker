require "rails_helper"

RSpec.describe PriceChangeCheckJob, type: :job do
  it "is queued on the default queue" do
    expect(described_class.new.queue_name).to eq("default")
  end

  it "runs without error (stub, Phase 2 fills in the real logic)" do
    expect { described_class.perform_now }.not_to raise_error
  end
end
