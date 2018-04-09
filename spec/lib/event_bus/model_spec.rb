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

    context 'when message given' do
      before do
        model.class_eval do
          event_bus_callback(fire_on: :create, condition: nil, exchange_hub: :some_hub, message: 'some string')
        end
      end

      it 'sets pushes correct message to publisher' do
        expect(EventBus::Publisher).to receive(:publish).with(payload: 'some string', exchange: :some_hub)
        model.create!(id: 1)
      end

    end

    context 'when block given' do
      before do
        model.class_eval do
          event_bus_callback(fire_on: :create, condition: nil, exchange_hub: :some_hub) do |record|
            { "#{record.model_name}_id" => record.id, some_text: :other_text }
          end
        end
      end

      it 'sets pushes correct message to publisher' do
        expect(EventBus::Publisher).to receive(:publish).with(payload: { 'test_id' => 2, some_text: :other_text }, exchange: :some_hub)
        model.create! id: 2
      end
    end

    context 'when fire on create defined' do
      let!(:inst){ model.create! }
      before do
        model.class_eval do
          event_bus_callback(fire_on: :create, condition: nil, exchange_hub: :some_hub, message: { event: :other_event })
        end
      end

      it 'fires on create with correct payload' do
        expect(EventBus::Publisher).to receive(:publish).with(payload: ({ event: :other_event }), exchange: :some_hub)
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
          event_bus_callback(fire_on: :update, condition: nil, exchange_hub: :some_hub, message: { event: :updated })
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
        expect(EventBus::Publisher).to receive(:publish).with(payload: ({ event: :updated }), exchange: :some_hub)
        inst.update! id: 1
      end

    end

    context 'when fire on destroy defined' do
      let(:inst){ model.create! }
      before do
        model.class_eval do
          event_bus_callback(fire_on: :destroy, condition: nil, exchange_hub: :some_hub, message: { event: :destroyed })
        end
      end

      it 'fires on destroy with correct payload' do
        expect(EventBus::Publisher).to receive(:publish).with(payload: ({ event: :destroyed }), exchange: :some_hub)
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
