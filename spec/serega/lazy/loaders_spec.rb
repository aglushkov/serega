# frozen_string_literal: true

RSpec.describe Serega::SeregaLazy do
  describe Serega::SeregaLazy::PointLazyLoader do
    subject(:loader) { described_class.new(point) }

    let(:point) { double(class: double(serializer_class: serializer_class)) }
    let(:serializer_class) { double(lazy_loaders: lazy_loaders) }
    let(:lazy_loaders) { {user: lazy_loader} }
    let(:lazy_loader) { double(load: lazy_data) }
    let(:lazy_data) { {1 => "John", 2 => "Jane"} }

    describe "#append" do
      let(:serializer) { double(__send__: nil) }
      let(:object) { double }
      let(:container) { double }

      it "adds object and container to collections" do
        loader.append(serializer, object, container)
        expect(loader.send(:objects)).to eq([object])
        expect(loader.send(:serializer_object_containers).first).to be_a(Serega::SeregaLazy::SerializerObjectContainer)
        expect(loader.send(:serializer_object_containers).first.serializer).to eq(serializer)
        expect(loader.send(:serializer_object_containers).first.object).to eq(object)
        expect(loader.send(:serializer_object_containers).first.container).to eq(container)
      end
    end

    describe "#load_all" do
      let(:serializer) { double(__send__: nil) }
      let(:object1) { double(id: 1) }
      let(:object2) { double(id: 2) }
      let(:container1) { double }
      let(:container2) { double }
      let(:context) { double }

      before do
        allow(point).to receive(:lazy_loaders).and_return([:user])
        loader.append(serializer, object1, container1)
        loader.append(serializer, object2, container2)
      end

      it "loads all lazy values and attaches them to objects" do
        allow(serializer).to receive(:__send__)
        loader.load_all(context)
        expect(lazy_loader).to have_received(:load).with([object1, object2], context)

        expect(serializer).to have_received(:__send__)
          .with(:attach_value, object1, point, container1, lazy: {user: lazy_data})

        expect(serializer).to have_received(:__send__)
          .with(:attach_value, object2, point, container2, lazy: {user: lazy_data})
      end
    end
  end

  describe Serega::SeregaLazy::Loaders do
    subject(:loaders) { described_class.new }

    describe "#remember" do
      let(:serializer) { double }
      let(:point) { double }
      let(:object) { double }
      let(:container) { double }

      it "creates new point lazy loader for new point" do
        loaders.remember(serializer, point, object, container)
        expect(loaders.send(:point_lazy_loaders).size).to eq(1)
        expect(loaders.send(:point_lazy_loaders).first).to be_a(Serega::SeregaLazy::PointLazyLoader)
      end

      it "reuses existing point lazy loader for same point" do
        loaders.remember(serializer, point, object, container)
        loaders.remember(serializer, point, object, container)
        expect(loaders.send(:point_lazy_loaders).size).to eq(1)
      end

      it "creates separate point lazy loader for different points" do
        point2 = double
        loaders.remember(serializer, point, object, container)
        loaders.remember(serializer, point2, object, container)
        expect(loaders.send(:point_lazy_loaders).size).to eq(2)
      end
    end

    describe "#load_all" do
      let(:context) { double }
      let(:point1) { double }
      let(:point2) { double }
      let(:serializer) { double }
      let(:object) { double }
      let(:container) { double }

      before do
        loaders.remember(serializer, point1, object, container)
        loaders.remember(serializer, point2, object, container)
      end

      it "loads all point lazy loaders" do
        point_loader1 = loaders.send(:point_lazy_loaders).first
        point_loader2 = loaders.send(:point_lazy_loaders).last
        allow(point_loader1).to receive(:load_all)
        allow(point_loader2).to receive(:load_all)

        loaders.load_all(context)

        expect(point_loader1).to have_received(:load_all).with(context)
        expect(point_loader2).to have_received(:load_all).with(context)
      end
    end
  end
end
