# frozen_string_literal: true

load_plugin_code :preloads

RSpec.describe Serega::SeregaPlugins::Preloads do
  let(:serializer_class) { Class.new(Serega) { plugin :preloads } }

  describe "AttributeNormalizerMethods" do
    let(:normalizer_class) { serializer_class::SeregaAttributeNormalizer }
    let(:initials) { {name: :foo, opts: opts, block: nil} }
    let(:opts) { {} }
    let(:norm) { normalizer_class.new(**initials) }

    describe "#preloads" do
      it "returns empty hash for regular attributes" do
        expect(norm.preloads).to eq({})
      end

      it "returns nil when provided nil" do
        opts[:preload] = nil
        expect(norm.preloads).to be_nil
      end

      it "returns formatted provided preloads" do
        opts[:preload] = :bar
        expect(norm.preloads).to eq(bar: {})
        expect(norm.preloads).to equal norm.preloads
      end

      it "returns automatically found preloads when serializer provided" do
        serializer_class.config.preloads.auto_preload_attributes_with_serializer = true
        opts[:serializer] = "bar"
        expect(norm.preloads).to eq(foo: {})
      end

      it "returns no preloads for attributes with serializer by default" do
        opts[:serializer] = "bar"
        expect(norm.preloads).to eq({})
      end

      it "returns automatically found preloads when :delegate option provided" do
        serializer_class.config.preloads.auto_preload_attributes_with_delegate = true
        opts[:delegate] = {to: :bar}
        expect(norm.preloads).to eq(bar: {})
      end

      it "returns no preloads for attributes with :delegate option by default" do
        opts[:delegate] = {to: :bar}
        expect(norm.preloads).to eq({})
      end
    end

    describe "#preload_path" do
      it "returns constructed preload_path" do
        opts[:preload] = :foo
        expect(norm.preloads_path).to eq([:foo])
        expect(norm.preloads_path).to be_frozen
        expect(norm.preloads_path).to equal norm.preloads_path
      end

      it "returns provided preload_path" do
        opts[:serializer] = "foo"
        opts[:preload] = %i[bar bazz]
        opts[:preload_path] = :bar
        expect(norm.preloads_path).to eq([:bar])
        expect(norm.preloads_path).to be_frozen
      end

      it "returns symbolized preload_path" do
        opts[:serializer] = "foo"
        opts[:preload] = %i[bar bazz]
        opts[:preload_path] = "bar"
        expect(norm.preloads_path).to eq([:bar])
      end

      it "returns symbolized preload_path when array provided" do
        opts[:serializer] = "foo"
        opts[:preload] = %i[bar bazz]
        opts[:preload_path] = %w[bar]
        expect(norm.preloads_path).to eq([:bar])
      end

      it "returns normalized array of provided paths" do
        opts[:serializer] = "foo"
        opts[:preload] = %i[bar bazz]
        opts[:preload_path] = [["bar"], ["bar", :bazz]]
        expect(norm.preloads_path).to eq([%i[bar], %i[bar bazz]])
        expect(norm.preloads_path).to be_frozen
      end

      it "returns nil if nil provided" do
        opts[:serializer] = "foo"
        opts[:preload] = %i[bar bazz]
        opts[:preload_path] = nil
        expect(norm.preloads_path).to be_nil
      end
    end

    describe "checking preload option" do
      let(:validator) { described_class::CheckOptPreload }

      it "validates options with CheckOptPreload" do
        allow(validator).to receive(:call).and_return(nil)
        attribute = serializer_class.attribute :foo
        expect(validator).to have_received(:call).with(attribute.initials[:opts])
      end
    end

    describe "checking preload_path option" do
      let(:validator) { described_class::CheckOptPreloadPath }

      it "validates options with CheckOptPreloadPath" do
        allow(validator).to receive(:call).and_return(nil)
        attribute = serializer_class.attribute :foo
        expect(validator).to have_received(:call).with(attribute.initials[:opts])
      end
    end

    describe "#hide" do
      context "without auto_hide config" do
        it "returns opt :hide" do
          a0 = serializer_class.attribute :a0
          a1 = serializer_class.attribute :a1, preload: :a1
          a2 = serializer_class.attribute :a2, preload: :a2, hide: true
          a3 = serializer_class.attribute :a3, preload: :a3, hide: false

          expect(a0.hide).to be_nil
          expect(a1.hide).to be_nil
          expect(a2.hide).to be true
          expect(a3.hide).to be false
        end
      end

      context "with auto_hide config" do
        before do
          serializer_class.config.preloads.auto_hide_attributes_with_preload = true
        end

        it "returns opt :hide => true when preload is not blank" do
          a0 = serializer_class.attribute :a0
          a1 = serializer_class.attribute :a1, preload: :a1
          a2 = serializer_class.attribute :a2, preload: :a2, hide: true
          a3 = serializer_class.attribute :a3, preload: :a3, hide: false
          a4 = serializer_class.attribute :a4, preload: nil
          a5 = serializer_class.attribute :a5, preload: false
          a6 = serializer_class.attribute :a6, preload: {}
          a7 = serializer_class.attribute :a7, preload: []

          expect(a0.hide).to be_nil
          expect(a1.hide).to be true
          expect(a2.hide).to be true
          expect(a3.hide).to be false
          expect(a4.hide).to be_nil
          expect(a5.hide).to be_nil
          expect(a6.hide).to be_nil
          expect(a7.hide).to be_nil
        end
      end
    end
  end
end
