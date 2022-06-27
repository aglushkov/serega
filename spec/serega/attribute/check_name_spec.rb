RSpec.describe Serega::Attribute::CheckName do
  def error(name)
    %(Invalid attribute name = #{name.inspect}. Globally allowed characters: "a-z", "A-Z", "0-9". Minus and low line "-", "_" also allowed except as the first or last character)
  end

  it "prohibits empty name" do
    name = ""
    expect { described_class.call(name) }.to raise_error Serega::Error, error(name)
  end

  it "allows one char A-Za-z0-9" do
    expect { described_class.call("a") }.not_to raise_error
    expect { described_class.call("s") }.not_to raise_error
    expect { described_class.call("z") }.not_to raise_error
    expect { described_class.call("A") }.not_to raise_error
    expect { described_class.call("S") }.not_to raise_error
    expect { described_class.call("Z") }.not_to raise_error
    expect { described_class.call("0") }.not_to raise_error
    expect { described_class.call("5") }.not_to raise_error
    expect { described_class.call("9") }.not_to raise_error

    expect { described_class.call("-") }.to raise_error Serega::Error, error("-")
    expect { described_class.call("`") }.to raise_error Serega::Error, error("`")
    expect { described_class.call("_") }.to raise_error Serega::Error, error("_")
  end

  it "allows two chars A-Za-z0-9" do
    expect { described_class.call("aZ") }.not_to raise_error
    expect { described_class.call("Za") }.not_to raise_error
    expect { described_class.call("09") }.not_to raise_error

    expect { described_class.call("a~") }.to raise_error Serega::Error, error("a~")
    expect { described_class.call("a-") }.to raise_error Serega::Error, error("a-")
    expect { described_class.call("-a") }.to raise_error Serega::Error, error("-a")
    expect { described_class.call("_a") }.to raise_error Serega::Error, error("_a")
    expect { described_class.call("a_") }.to raise_error Serega::Error, error("a_")
  end

  it 'allows multiple chars A-Za-z0-9 with "-" and "_" in the middle' do
    expect { described_class.call("foo") }.not_to raise_error
    expect { described_class.call("bar") }.not_to raise_error
    expect { described_class.call("fooBAR123") }.not_to raise_error
    expect { described_class.call("foo-123") }.not_to raise_error
    expect { described_class.call("foo_3") }.not_to raise_error

    expect { described_class.call("foo-") }.to raise_error Serega::Error, error("foo-")
    expect { described_class.call("foo_") }.to raise_error Serega::Error, error("foo_")
    expect { described_class.call("-foo") }.to raise_error Serega::Error, error("-foo")
    expect { described_class.call("_foo") }.to raise_error Serega::Error, error("_foo")
    expect { described_class.call("foo+bar") }.to raise_error Serega::Error, error("foo+bar")
  end
end
