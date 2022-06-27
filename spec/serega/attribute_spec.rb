# frozen_string_literal: true

RSpec.describe Serega::Attribute do
  let(:serializer_class) { Class.new(Serega) }
  let(:attribute_class) { serializer_class::Attribute }

  describe ".initialize" do
    before do
      allow(described_class::CheckName).to receive(:call)
      allow(described_class::CheckOpts).to receive(:call)
      allow(described_class::CheckBlock).to receive(:call)
    end

    it "validates provided params" do
      block = proc {}
      attribute_class.new(name: :current_name, opts: {foo: :bar}, block: block)

      expect(described_class::CheckName).to have_received(:call).with(:current_name)
      expect(described_class::CheckOpts).to have_received(:call).with({foo: :bar}, serializer_class.config[:allowed_opts])
      expect(described_class::CheckBlock).to have_received(:call).with(block)
    end

    it "symbolizes name" do
      expect(attribute_class.new(name: "current_name").name).to eq :current_name
    end

    it "duplicates provided options" do
      opts = {many: true}
      attr_opts = attribute_class.new(name: :name, opts: opts).opts
      expect(opts).to eql attr_opts
      expect(attr_opts).not_to be(opts)
    end

    it "saves provided block" do
      block = proc {}
      expect(attribute_class.new(name: :name).block).to be_nil
      expect(attribute_class.new(name: :name, block: block).block).to eq block
    end
  end

  describe "#name" do
    it "symbolizes name" do
      attribute = attribute_class.new(name: "current_name")
      expect(attribute.name).to eq :current_name
    end
  end

  describe "#key" do
    it "returns symbolized :key options" do
      attribute = attribute_class.new(name: "current_name", opts: {key: "key"})
      expect(attribute.key).to eq :key
    end

    it "returns name when :key option not provided" do
      attribute = attribute_class.new(name: "current_name")
      expect(attribute.key).to eq :current_name
    end
  end

  describe "#many" do
    it "returns provided :many option" do
      expect(attribute_class.new(name: :name, opts: {many: true}).many).to be true
      expect(attribute_class.new(name: :name, opts: {many: false}).many).to be false
      expect(attribute_class.new(name: :name).many).to be_nil
    end
  end

  describe "#hide" do
    it "returns provided :hide option" do
      expect(attribute_class.new(name: :name, opts: {hide: true}).hide).to be true
      expect(attribute_class.new(name: :name, opts: {hide: false}).hide).to be false
      expect(attribute_class.new(name: :name).hide).to be_nil
    end
  end

  describe "#relation?" do
    it "returns true if serializer option provided" do
      expect(attribute_class.new(name: :name).relation?).to be false
      expect(attribute_class.new(name: :name, opts: {serializer: serializer_class}).relation?).to be true
    end
  end

  describe "#serializer" do
    let(:ser) { Class.new(Serega) }
    let(:proc_ser) { proc { ser } }

    it "returns provided :serializer option" do
      expect(attribute_class.new(name: :name, opts: {serializer: ser}).serializer).to eq ser
    end

    it "extracts provided :serializer from Proc" do
      expect(attribute_class.new(name: :name, opts: {serializer: proc_ser}).serializer).to eq ser
    end

    it "extracts provided :serializer from String" do
      Object.const_set(:AAA, ser)
      expect(attribute_class.new(name: :name, opts: {serializer: "AAA"}).serializer).to eq ser
    end
  end

  describe "#value_block" do
    it "returns provided block" do
      block = proc {}
      expect(attribute_class.new(name: :name, block: block).value_block).to eq block
    end

    it "returns automatically created block when block not provided that returns object#key" do
      block = attribute_class.new(name: :name, opts: {key: :length}).value_block
      expect(block).to be_a Proc
      expect(block.call(double(length: 3))).to eq 3
    end
  end

  describe "#value" do
    it "takes value_block and executes it with two params (object, context)" do
      obj = double(length: 3)
      context = {foo: :bar}
      block = proc { |object, ctx| [object.length, ctx[:foo]] }

      attribute = attribute_class.new(name: :name, block: block)
      expect(attribute.value(obj, context)).to eq [3, :bar]
    end
  end

  describe "#visible?" do
    def default
      {except: {}, only: {}, with: {}}
    end

    def except(key)
      {except: {key => {}}, only: {}, with: {}}
    end

    def only(key)
      {except: {}, only: {key => {}}, with: {}}
    end

    def with(key)
      {except: {}, only: {}, with: {key => {}}}
    end

    it "returns by default true when attribute is not hidden" do
      expect(attribute_class.new(name: :name).visible?(**default)).to be true
    end

    it "returns by default false when attribute is hidden" do
      expect(attribute_class.new(name: :name, opts: {hide: true}).visible?(**default)).to be false
    end

    it "returns false when attribute is hidden via :only parameter" do
      expect(attribute_class.new(name: :name).visible?(**only(:other))).to be false
    end

    it "returns true when attribute is shown via :only parameter" do
      expect(attribute_class.new(name: :name, opts: {hide: true}).visible?(**only(:name))).to be true
    end

    it "returns true when attribute is shown via :with parameter" do
      expect(attribute_class.new(name: :name, opts: {hide: true}).visible?(**with(:name))).to be true
    end

    it "returns false when attribute is hidden via :except parameter" do
      expect(attribute_class.new(name: :name).visible?(**except(:name))).to be false
    end

    it "skips :except parameter if it has nested keys" do
      args = except(:name)
      args[:except][:name] = {foo: {}}

      expect(attribute_class.new(name: :name).visible?(**args)).to be true
    end
  end
end
