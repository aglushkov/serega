# frozen_string_literal: true

load_plugin_code :root

RSpec.describe Serega::SeregaPlugins::Root do
  describe "configuration" do
    let(:serializer) { Class.new(Serega) { plugin :root } }

    it "preserves root config" do
      root1 = serializer.config.root
      root2 = serializer.config.root
      expect(root1).to be root2
    end

    it "allows to change root via #one= and #many= methods" do
      root = serializer.config.root
      root.one = :new_one
      root.many = :new_many

      expect(root.one).to eq :new_one
      expect(root.many).to eq :new_many
    end
  end

  describe "serialization" do
    let(:response) { user_serializer.new.to_h(user) }

    context "with default root" do
      let(:base_serializer) { Class.new(Serega) { plugin :root } }
      let(:user) { double(first_name: "FIRST_NAME") }
      let(:user_serializer) do
        Class.new(base_serializer) do
          attribute :first_name
        end
      end

      it "adds default root key to single object response" do
        response = user_serializer.new.to_h(user)
        expect(response).to eq(data: {first_name: "FIRST_NAME"})
      end

      it "adds default root key to multiple objects response" do
        response = user_serializer.new.to_h([user])
        expect(response).to eq(data: [{first_name: "FIRST_NAME"}])
      end
    end

    context "with different root key for one or many serialized resources" do
      let(:user) { double(first_name: "FIRST_NAME") }
      let(:user_serializer) do
        Class.new(Serega) do
          plugin :root, root_one: "user", root_many: "users"
          attribute :first_name
        end
      end

      it "adds root key to single object response" do
        response = user_serializer.new.to_h(user)
        expect(response).to eq(user: {first_name: "FIRST_NAME"})
      end

      it "adds root key to multiple objects response" do
        response = user_serializer.new.to_h([user])
        expect(response).to eq(users: [{first_name: "FIRST_NAME"}])
      end
    end

    context "with root provided as DSL method" do
      let(:user) { double(first_name: "FIRST_NAME") }
      let(:user_serializer) do
        Class.new(Serega) do
          plugin :root
          attribute :first_name
        end
      end

      it "adds root key to single object response" do
        user_serializer.root one: :customer
        response = user_serializer.new.to_h(user)
        expect(response).to eq(customer: {first_name: "FIRST_NAME"})
      end

      it "adds root key to multiple objects response" do
        user_serializer.root many: :customers
        response = user_serializer.new.to_h([user])
        expect(response).to eq(customers: [{first_name: "FIRST_NAME"}])
      end
    end

    context "with root provided as serialization option" do
      let(:user) { double(first_name: "FIRST_NAME") }
      let(:user_serializer) do
        Class.new(Serega) do
          plugin :root
          attribute :first_name
        end
      end

      it "adds root key to single object response" do
        response = user_serializer.new.to_h(user, root: :customer)
        expect(response).to eq(customer: {first_name: "FIRST_NAME"})
      end

      it "adds root key to multiple objects response" do
        response = user_serializer.new.to_h([user], root: :customers)
        expect(response).to eq(customers: [{first_name: "FIRST_NAME"}])
      end

      it "removes root key when nil provided" do
        response = user_serializer.new.to_h([user], root: nil)
        expect(response).to eq([{first_name: "FIRST_NAME"}])
      end
    end
  end
end
