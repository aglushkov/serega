# frozen_string_literal: true

RSpec.describe Serega::SeregaConvert do
  subject { user_serializer.new(context).to_h(user) }

  let(:user_serializer) do
    Class.new(Serega) do
      attribute :first_name
      attribute :last_name
    end
  end
  let(:context) { {} }

  context "with nil object" do
    let(:user) { nil }

    it "returns empty hash" do
      expect(subject).to eq({})
    end
  end

  context "with empty array" do
    let(:user) { [] }

    it "returns empty array" do
      expect(subject).to eq([])
    end
  end

  context "with object with attributes" do
    let(:user) { double(first_name: "FIRST_NAME", last_name: "LAST_NAME") }

    it "returns hash" do
      expect(subject).to eq({first_name: "FIRST_NAME", last_name: "LAST_NAME"})
    end
  end

  context "with object with relation" do
    let(:comment) { double(text: "TEXT") }
    let(:comment_serializer) do
      Class.new(Serega) do
        attribute :text
      end
    end

    let(:user) { double(first_name: "FIRST_NAME", last_name: "LAST_NAME", comment: comment) }
    let(:user_serializer) do
      child_serializer = comment_serializer
      Class.new(Serega) do
        attribute :first_name
        attribute :last_name
        relation :comment, serializer: child_serializer
      end
    end

    it "returns hash with relations" do
      expect(subject).to eq({first_name: "FIRST_NAME", last_name: "LAST_NAME", comment: {text: "TEXT"}})
    end
  end

  context "with object with array relation" do
    let(:comments) { [double(text: "TEXT")] }
    let(:comment_serializer) do
      Class.new(Serega) do
        attribute :text
      end
    end

    let(:user) { double(first_name: "FIRST_NAME", last_name: "LAST_NAME", comments: comments) }
    let(:user_serializer) do
      child_serializer = comment_serializer
      Class.new(Serega) do
        attribute :first_name
        attribute :last_name
        relation :comments, serializer: child_serializer
      end
    end

    it "returns hash with relations" do
      expect(subject).to eq({first_name: "FIRST_NAME", last_name: "LAST_NAME", comments: [{text: "TEXT"}]})
    end
  end

  context "with object with hidden attribute" do
    let(:user) { double(first_name: "FIRST_NAME", last_name: "LAST_NAME") }
    let(:user_serializer) do
      Class.new(Serega) do
        attribute :first_name, hide: true
        attribute :last_name
      end
    end

    it "returns serialized object without hidden attributes" do
      expect(subject).to eq({last_name: "LAST_NAME"})
    end
  end

  context "with `:with` context option" do
    let(:user) { double(first_name: "FIRST_NAME", last_name: "LAST_NAME") }
    let(:user_serializer) do
      Class.new(Serega) do
        attribute :first_name, hide: true
        attribute :last_name
      end
    end

    let(:context) { {with: :first_name} }

    it "returns specified in `:with` option hidden attributes" do
      expect(subject).to include({first_name: "FIRST_NAME"})
    end
  end

  context "with `:only` context option" do
    let(:user) { double(first_name: "FIRST_NAME", last_name: "LAST_NAME") }
    let(:user_serializer) do
      Class.new(Serega) do
        attribute :first_name, hide: true
        attribute :last_name
      end
    end

    let(:context) { {only: :first_name} }

    it "returns hash with `only` selected attributes" do
      expect(subject).to eq({first_name: "FIRST_NAME"})
    end
  end

  context "with :except option" do
    let(:user) { double(first_name: "FIRST_NAME", last_name: "LAST_NAME") }
    let(:context) { {except: :first_name} }

    it "returns hash without :excepted attributes" do
      expect(subject).to eq({last_name: "LAST_NAME"})
    end
  end

  context "with `:with` context option provided as Array" do
    let(:user) { double(first_name: "FIRST_NAME", last_name: "LAST_NAME") }
    let(:user_serializer) do
      Class.new(Serega) do
        attribute :first_name, hide: true
        attribute :last_name, hide: true
      end
    end

    let(:context) { {with: %w[first_name last_name]} }

    it "returns specified in `:with` option hidden attributes" do
      expect(subject).to include({first_name: "FIRST_NAME", last_name: "LAST_NAME"})
    end
  end

  context "with `:only` context option provided as Array" do
    let(:user) { double(first_name: "FIRST_NAME", last_name: "LAST_NAME", middle_name: "MIDDLE_NAME") }
    let(:user_serializer) do
      Class.new(Serega) do
        attribute :first_name, hide: true
        attribute :last_name, hide: true
        attribute :middle_name
      end
    end

    let(:context) { {only: %i[first_name last_name]} }

    it "returns hash with `only` selected attributes" do
      expect(subject).to eq({first_name: "FIRST_NAME", last_name: "LAST_NAME"})
    end
  end

  context "with :except option provided as Array" do
    let(:user) { double(first_name: "FIRST_NAME", last_name: "LAST_NAME", middle_name: "MIDDLE_NAME") }
    let(:user_serializer) do
      Class.new(Serega) do
        attribute :first_name
        attribute :last_name
        attribute :middle_name
      end
    end

    let(:context) { {except: %i[first_name last_name]} }

    it "returns hash without :excepted attributes" do
      expect(subject).to eq({middle_name: "MIDDLE_NAME"})
    end
  end

  context "with `:with` context option provided as Hash" do
    let(:comment) { double(text: "TEXT") }
    let(:comment_serializer) do
      Class.new(Serega) do
        attribute :text, hide: true
      end
    end

    let(:user) { double(first_name: "FIRST_NAME", last_name: "LAST_NAME", comment: comment) }
    let(:user_serializer) do
      child_serializer = comment_serializer
      Class.new(Serega) do
        attribute :first_name
        attribute :last_name, hide: true
        relation :comment, serializer: child_serializer, hide: true
      end
    end

    let(:context) { {with: {comment: :text}} }

    it "returns hash with additional attributes specified in `:with` option" do
      expect(subject).to include({first_name: "FIRST_NAME", comment: {text: "TEXT"}})
    end
  end

  context "with `:only` context option provided as Hash" do
    let(:comment) { double(text: "TEXT") }
    let(:comment_serializer) do
      Class.new(Serega) do
        attribute :text
      end
    end

    let(:user) { double(first_name: "FIRST_NAME", last_name: "LAST_NAME", comment: comment) }
    let(:user_serializer) do
      child_serializer = comment_serializer
      Class.new(Serega) do
        attribute :first_name
        attribute :last_name
        relation :comment, serializer: child_serializer
      end
    end

    let(:context) { {only: {comment: :text}} }

    it "returns hash with `only` selected attributes" do
      expect(subject).to eq({comment: {text: "TEXT"}})
    end
  end

  context "with :except option provided as Hash" do
    let(:comment) { double(text: "TEXT") }
    let(:comment_serializer) do
      Class.new(Serega) do
        attribute :text
      end
    end

    let(:user) { double(first_name: "FIRST_NAME", last_name: "LAST_NAME", comment: comment) }
    let(:user_serializer) do
      child_serializer = comment_serializer
      Class.new(Serega) do
        attribute :first_name
        attribute :last_name
        relation :comment, serializer: child_serializer
      end
    end

    let(:context) { {except: {comment: :text}} }

    it "returns hash without excepted attributes" do
      expect(subject).to eq({first_name: "FIRST_NAME", last_name: "LAST_NAME", comment: {}})
    end
  end

  context "with :except of relation" do
    let(:comment) { double(text: "TEXT") }
    let(:comment_serializer) do
      Class.new(Serega) do
        attribute :text
      end
    end

    let(:user) { double(first_name: "FIRST_NAME", last_name: "LAST_NAME", comment: comment) }
    let(:user_serializer) do
      child_serializer = comment_serializer
      Class.new(Serega) do
        attribute :first_name
        attribute :last_name
        relation :comment, serializer: child_serializer
      end
    end

    let(:context) { {except: :comment} }

    it "returns hash without excepted attributes" do
      expect(subject).to eq({first_name: "FIRST_NAME", last_name: "LAST_NAME"})
    end
  end

  context "with :only relation" do
    let(:comment) { double(text: "TEXT") }
    let(:comment_serializer) do
      Class.new(Serega) do
        attribute :text
      end
    end

    let(:user) { double(first_name: "FIRST_NAME", last_name: "LAST_NAME", comment: comment) }
    let(:user_serializer) do
      child_serializer = comment_serializer
      Class.new(Serega) do
        attribute :first_name
        attribute :last_name
        relation :comment, serializer: child_serializer
      end
    end

    let(:context) { {only: :comment} }

    it "returns hash with only requested fields and all fields of requested relation" do
      expect(subject).to eq({comment: {text: "TEXT"}})
    end
  end
end
