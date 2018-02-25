require 'spec_helper'

RSpec.describe EventBus::Model, :db do

  let(:model) do
    klass = Class.new(ActiveRecord::Base)

    klass.class_eval do
      self.table_name = 'test'
      def self.model_name
        ActiveModel::Name.new(self, nil, "test")
      end
    end

    klass.include(described_class)
    klass
  end

  it 'responds to needed methods' do
    expect(model).to respond_to(:event_bus_callback, :after_commit, :after_destroy)
  end

  describe 'firing callbacks' do

    context 'when class_name given' do
      before do
        model.class_eval do
          event_bus_callback(event: :updated, fire_on: :create, condition: nil, exchange_hub: :some_hub, class_name: :visit)
        end
      end

      it 'sets correct class name in payload' do
        expect(EventBus::Publisher).to receive(:publish).with(payload: ({ 'visit' => 1, event: :updated}), exchange: :some_hub)
        model.create!(id: 1)
      end

    end

    context 'when class_name is not given' do
      before do
        model.class_eval do
          event_bus_callback(event: :updated, fire_on: :create, condition: nil, exchange_hub: :some_hub)
        end
      end

      it 'sets correct class name in payload' do
        expect(EventBus::Publisher).to receive(:publish).with(payload: ({ 'test' => 2, event: :updated}), exchange: :some_hub)
        model.create! id: 2
      end
    end

    context 'when fire on create defined' do
      let!(:inst){ model.create! }
      before do
        model.class_eval do
          event_bus_callback(event: :other_event, fire_on: :create, condition: nil, exchange_hub: :some_hub)
        end
      end

      it 'fires on create with correct payload' do
        expect(EventBus::Publisher).to receive(:publish).with(payload: ({ 'test' => 2, event: :other_event}), exchange: :some_hub)
        model.create! id: 2
      end

      it 'doesnt fire on destroy' do
        expect(EventBus::Publisher).not_to receive(:publish)
        inst.destroy
      end


      it 'doesnt fire on update' do
        expect(EventBus::Publisher).not_to receive(:publish)
        inst.reload.update! id: 3
      end

    end

    context 'when fire on update defined' do
      let(:inst){ model.create! }
      before do
        model.class_eval do
          event_bus_callback(event: :updated, fire_on: :update, condition: nil, exchange_hub: :some_hub)
        end
      end

      it 'doesnt fire on create' do
        expect(EventBus::Publisher).not_to receive(:publish)
        model.create! id: 2
      end

      it 'doesnt fire on destroy' do
        expect(EventBus::Publisher).not_to receive(:publish)
        inst.destroy
      end


      it 'fires on update with correct pyload' do
        expect(EventBus::Publisher).to receive(:publish).with(payload: ({ 'test' => 1, event: :updated}), exchange: :some_hub)
        inst.update! id: 1
      end

    end

    context 'when fire on destroy defined' do
      let(:inst){ model.create! }
      before do
        model.class_eval do
          event_bus_callback(event: :destroyed, fire_on: :destroy, condition: nil, exchange_hub: :some_hub)
        end
      end

      it 'fires on destroy with correct payload' do
        expect(EventBus::Publisher).to receive(:publish).with(payload: ({ 'test' => 1, event: :destroyed}), exchange: :some_hub)
        inst.destroy
      end

      it 'doesnt fire on create' do
        expect(EventBus::Publisher).not_to receive(:publish)
        model.create! id: 2
      end

      it 'doesnt fire on update' do
        expect(EventBus::Publisher).not_to receive(:publish)
        inst.reload.update! id: 3
      end

    end
  end

end