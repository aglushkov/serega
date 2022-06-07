# frozen_string_literal: true

RSpec.describe "Serega::Plugins::Root" do
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
  end
end
