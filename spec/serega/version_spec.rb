# frozen_string_literal: true

RSpec.describe Serega do
  subject(:version) { described_class::VERSION }

  it "has a version number" do
    expect(version).to be_a String
    expect(version.count(".")).to be >= 2
    expect { Gem::Version.new(version) }.not_to raise_error
  end
end
