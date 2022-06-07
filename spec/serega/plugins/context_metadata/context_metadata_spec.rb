# frozen_string_literal: true

RSpec.describe "Serega::Plugins::ContextMetadata" do
  describe "loading" do
    it "loads additional :root plugin if was not loaded before" do
      serializer = Class.new(Serega) { plugin :context_metadata }
      expect(serializer.plugin_used?(:root)).to be true
    end

    it "loads additional :root plugin with custom root config" do
      serializer = Class.new(Serega) { plugin :context_metadata, root_one: :user, root_many: :users }
      expect(serializer.config[:root_one]).to eq :user
      expect(serializer.config[:root_many]).to eq :users
    end

    it "adds default :context_metadata_key config option" do
      serializer = Class.new(Serega) { plugin :context_metadata }
      expect(serializer.config[:context_metadata_key]).to eq :meta
    end

    it "adds specified :context_metadata_key config option" do
      serializer = Class.new(Serega) { plugin :context_metadata, context_metadata_key: :metadata }
      expect(serializer.config[:context_metadata_key]).to eq :metadata
    end
  end

  describe "validations" do
    let(:default_serializer) { Class.new(Serega) { plugin :context_metadata } }

    it "raises error when default context meta key is not a Hash" do
      ser = Class.new(Serega) { plugin :context_metadata }
      expect { ser.new(meta: []) }
        .to raise_error Serega::Error, "Option :meta must be a Hash, but Array was given"
    end

    it "raises error when configured context meta key is not a Hash" do
      ser = Class.new(Serega) { plugin :context_metadata, context_metadata_key: :foo }
      expect { ser.new(foo: []) }
        .to raise_error Serega::Error, "Option :foo must be a Hash, but Array was given"
    end
  end

  describe "serialization" do
    subject(:response) { user_serializer.new(context).to_h(obj) }

    let(:obj) { double(first_name: "FIRST_NAME") }
    let(:context) { {meta: {version: "1.2.3"}} }
    let(:base_serializer) { Class.new(Serega) { plugin :context_metadata } }
    let(:user_serializer) do
      Class.new(base_serializer) do
        attribute :first_name
      end
    end

    context "with single object" do
      it "appends metadata attributes to response" do
        expect(response).to eq(data: {first_name: "FIRST_NAME"}, version: "1.2.3")
      end
    end

    context "with multiple objects" do
      let(:obj) { [double(first_name: "FIRST_NAME")] }

      it "appends metadata attributes to response" do
        expect(response).to eq(data: [{first_name: "FIRST_NAME"}], version: "1.2.3")
      end
    end

    context "with :metadata plugin" do
      let(:serializer) do
        Class.new(Serega) do
          plugin :metadata
          plugin :context_metadata

          meta_attribute(:foo, :one) { 1 }
          meta_attribute(:foo, :two) { 2 }
        end
      end

      it "merges metadata" do
        response = serializer.new(meta: {foo: {two: "two", three: "three"}}).to_h(nil)
        expect(response).to eq(
          data: {},
          foo: {one: 1, two: "two", three: "three"}
        )
      end
    end
  end
end
