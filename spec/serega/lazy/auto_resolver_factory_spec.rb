# frozen_string_literal: true

RSpec.describe Serega::SeregaLazy::AutoResolverFactory do
  let(:serializer_class) { Class.new(Serega) }
  let(:attribute_name) { :user }

  describe ".get" do
    subject(:resolver) { described_class.get(serializer_class, attribute_name, lazy_opt) }

    context "when lazy_opt is true" do
      let(:lazy_opt) { true }

      it "creates resolver with attribute name and :id method" do
        expect(resolver.loader_name).to eq(:user)
        expect(resolver.id_method).to eq(:id)
      end
    end

    context "when lazy_opt is a callable" do
      let(:lazy_opt) { proc { |objects| objects.map(&:id) } }

      it "creates resolver with attribute name and :id method" do
        allow(serializer_class).to receive(:lazy_loader)
        resolver
        expect(serializer_class).to have_received(:lazy_loader).with(:user, lazy_opt)
        expect(resolver.loader_name).to eq(:user)
        expect(resolver.id_method).to eq(:id)
      end
    end

    context "when lazy_opt is a hash with callable use" do
      let(:lazy_opt) { {use: proc { |objects| objects.map(&:id) }} }

      it "creates resolver with attribute name and :id method" do
        allow(serializer_class).to receive(:lazy_loader)
        resolver
        expect(serializer_class).to have_received(:lazy_loader).with(:user, lazy_opt[:use])
        expect(resolver.loader_name).to eq(:user)
        expect(resolver.id_method).to eq(:id)
      end
    end

    context "when lazy_opt is a hash with symbol use" do
      let(:lazy_opt) { {use: :custom_loader} }

      it "creates resolver with custom loader name and :id method" do
        expect(resolver.loader_name).to eq(:custom_loader)
        expect(resolver.id_method).to eq(:id)
      end
    end

    context "when lazy_opt is a hash with custom id method" do
      let(:lazy_opt) { {use: :custom_loader, id: :custom_id} }

      it "creates resolver with custom loader name and custom id method" do
        expect(resolver.loader_name).to eq(:custom_loader)
        expect(resolver.id_method).to eq(:custom_id)
      end
    end
  end
end
