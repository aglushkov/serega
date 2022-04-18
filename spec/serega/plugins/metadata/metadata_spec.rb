# frozen_string_literal: true

RSpec.describe "Serega::SeregaPlugins::Metadata" do
  describe "loading" do
    it "loads additional :root plugin if was not loaded before" do
      serializer = Class.new(Serega) { plugin :metadata }
      expect(serializer.plugin_used?(:root)).to be true
    end

    it "loads additional :root plugin with custom root config" do
      serializer = Class.new(Serega) { plugin :metadata, root_one: :user, root_many: :users }
      expect(serializer.config[:root_one]).to eq :user
      expect(serializer.config[:root_many]).to eq :users
    end
  end

  describe "inheritance" do
    let(:base_serializer) do
      Class.new(Serega) do
        plugin :metadata
        meta_attribute(:version, hide_nil: true) { "1.2.3" }
      end
    end

    let(:serializer) { Class.new(base_serializer) }

    it "inherits meta attributes" do
      meta_attributes = serializer.meta_attributes

      expect(meta_attributes.count).to eq 1
      expect(meta_attributes[0].path).to eq [:version]
      expect(meta_attributes[0].opts).to eq(hide_nil: true)
      expect(meta_attributes[0].value(nil, nil)).to eq "1.2.3"
    end
  end

  describe "serialization" do
    subject(:response) { user_serializer.new(context).to_h(obj) }

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
