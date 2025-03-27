# frozen_string_literal: true

RSpec.describe Serega::SeregaLazy::AutoResolver do
  let(:loader_name) { :user }
  let(:id_method) { :id }

  describe "#initialize" do
    subject(:resolver) { described_class.new(loader_name, id_method) }

    it "sets loader_name and id_method" do
      expect(resolver.loader_name).to eq(:user)
      expect(resolver.id_method).to eq(:id)
    end
  end

  describe "#call" do
    let(:obj) { double(id: 1) }
    let(:lazy_values) { {1 => "John"} }
    let(:lazy) { {user: lazy_values} }
    let(:resolver) { described_class.new(loader_name, id_method) }

    it "fetches value from lazy hash using object's id" do
      expect(resolver.call(obj, lazy: lazy)).to eq("John")
    end

    context "when using custom id method" do
      let(:id_method) { :user_id }
      let(:obj) { double(user_id: 2) }
      let(:lazy_values) { {2 => "Jane"} }

      it "fetches value using custom id method" do
        expect(resolver.call(obj, lazy: lazy)).to eq("Jane")
      end
    end

    context "when lazy hash is empty" do
      let(:lazy_values) { {} }

      it "raises KeyError" do
        expect(resolver.call(obj, lazy: lazy)).to be_nil
      end
    end

    context "when lazy hash doesn't contain loader_name" do
      let(:lazy) { {} }

      it "raises KeyError" do
        expect { resolver.call(obj, lazy: lazy) }.to raise_error(KeyError)
      end
    end
  end
end
