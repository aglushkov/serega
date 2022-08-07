# frozen_string_literal: true

load_plugin_code :metadata

RSpec.describe Serega::SeregaPlugins::Metadata do
  describe "loading" do
    it "loads additional :root plugin if was not loaded before" do
      serializer = Class.new(Serega) { plugin :metadata }
      expect(serializer.plugin_used?(:root)).to be true
    end

    it "loads additional :root plugin with custom root config" do
      serializer = Class.new(Serega) { plugin :metadata, root_one: :user, root_many: :users }
      expect(serializer.config.root.one).to eq :user
      expect(serializer.config.root.many).to eq :users
    end

    it "works when :root plugin it was loaded before" do
      serializer = Class.new(Serega)
      serializer.plugin :root
      expect { serializer.plugin :metadata }.not_to raise_error
    end

    it "configures :root plugin even when it was loaded before" do
      serializer = Class.new(Serega)
      serializer.plugin :root
      serializer.plugin :metadata, root_one: :one, root_many: :many
      root = serializer.config.root
      expect(root.one).to eq :one
      expect(root.many).to eq :many
    end
  end

  describe "inheritance" do
    let(:parent) { Class.new(Serega) { plugin :metadata } }
    let(:child) { Class.new(parent) }

    it "inherits MetaAttribute class" do
      expect(parent::MetaAttribute).to be child::MetaAttribute.superclass
    end

    it "inherits meta attributes" do
      parent_attr = parent.meta_attribute(:version, hide_nil: true) { "1.2.3" }

      expect(child.meta_attributes.length).to eq 1
      child_attr = child.meta_attributes[:version]
      expect(child_attr).not_to equal parent_attr
      expect(child_attr.opts).to eq(hide_nil: true)
      expect(child_attr.path).to eq([:version])
      expect(child_attr.value(nil, nil)).to eq "1.2.3"
    end

    it "allows to override meta attributes" do
      parent.meta_attribute(:version, :minor) { "1" }
      child_attr = child.meta_attributes[:"version.minor"]

      expect(child.meta_attributes.length).to eq 1
      expect(child_attr.value(nil, nil)).to eq "1"

      child.meta_attribute(:version, :minor) { "2" }
      expect(child.meta_attributes.length).to eq 1

      child_attr = child.meta_attributes[:"version.minor"]
      expect(child_attr.value(nil, nil)).to eq "2"
    end
  end

  describe "serialization" do
    subject(:response) { user_serializer.new.to_h(obj, context: context) }

    let(:obj) { double(first_name: "FIRST_NAME") }
    let(:context) { {} }
    let(:base_serializer) { Class.new(Serega) { plugin :metadata } }
    let(:user_serializer) do
      Class.new(base_serializer) do
        attribute :first_name
      end
    end

    context "with regular metadata with single object" do
      before { user_serializer.meta_attribute(:version) { "1.2.3" } }

      it "appends metadata attributes to response" do
        expect(response).to eq(data: {first_name: "FIRST_NAME"}, version: "1.2.3")
      end
    end

    context "with regular metadata with multiple objects" do
      let(:obj) { [double(first_name: "FIRST_NAME")] }

      before { user_serializer.meta_attribute(:version) { "1.2.3" } }

      it "appends metadata attributes to response" do
        expect(response).to eq(data: [{first_name: "FIRST_NAME"}], version: "1.2.3")
      end
    end

    context "with metadata with parameters" do
      let(:context) { {page: 2, per_page: 3} }

      before do
        user_serializer.meta_attribute(:meta, :paging) do |obj, context|
          {
            total_count: Array(obj).size,
            page: context[:page],
            per_page: context[:per_page]
          }
        end
      end

      it "appends metadata attributes to response" do
        expect(response).to eq(
          data: {first_name: "FIRST_NAME"},
          meta: {paging: {total_count: 1, page: 2, per_page: 3}}
        )
      end
    end

    describe "merging multiple metadata attributes" do
      let(:context) { {page: 2, per_page: 3} }

      before do
        user_serializer.meta_attribute(:version, :number) { "1.2.3" }
        user_serializer.meta_attribute(:version) { "1.2.3" }
        user_serializer.meta_attribute(:meta, :paging, :total_count) { |obj| Array(obj).count }
        user_serializer.meta_attribute(:meta, :paging, :page) { |_obj, ctx| ctx[:page] }
        user_serializer.meta_attribute(:meta, :paging, :per_page) { |_obj, ctx| ctx[:per_page] }
      end

      it "appends merged metadata attributes to response" do
        expect(response).to eq(
          data: {first_name: "FIRST_NAME"},
          version: "1.2.3",
          meta: {
            paging: {
              total_count: 1, page: 2, per_page: 3
            }
          }
        )
      end
    end

    describe "hiding metadata attributes" do
      let(:context) { {page: 2, per_page: 3} }

      before do
        user_serializer.meta_attribute(:meta, :test1, hide_nil: true) {}
        user_serializer.meta_attribute(:meta, :test2, hide_empty: true) { {} }
        user_serializer.meta_attribute(:meta, :test3, hide_empty: true) { [] }
        user_serializer.meta_attribute(:meta, :test4, hide_empty: true) { "" }
        user_serializer.meta_attribute(:meta, :test5) { nil }
        user_serializer.meta_attribute(:meta, :test6) { {} }
        user_serializer.meta_attribute(:meta, :test7) { [] }
        user_serializer.meta_attribute(:meta, :test8, hide_nil: true, hide_empty: true) { "foo" }
      end

      it "hides empty or nil attributes when :hide_nil / :hide_empty options provided" do
        expect(response).to eq(
          data: {first_name: "FIRST_NAME"},
          meta: {
            test5: nil,
            test6: {},
            test7: [],
            test8: "foo"
          }
        )
      end
    end
  end
end
