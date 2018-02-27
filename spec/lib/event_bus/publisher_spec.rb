require 'spec_helper'
require 'event_bus/connector'
require 'event_bus/configurator'
require 'event_bus/publisher'

RSpec.describe EventBus::Publisher do
  let!(:bunny_exchange_class){ class_double(Bunny::Exchange).as_stubbed_const }
  let!(:bunny_exchange_instance){ instance_double(Bunny::Exchange) }

  before do
    allow(bunny_exchange_instance).to receive(:publish)
    allow(Bunny::Exchange).to receive(:new).and_return(bunny_exchange_instance)

    allow_any_instance_of(EventBus::Connector).to receive(:connect)
    allow_any_instance_of(EventBus::Connector).to receive(:check_connection!)
    allow_any_instance_of(EventBus::Connector).to receive(:exchanges).and_return({'some' => bunny_exchange_instance})
  end

  describe '#publish' do

    it 'publishes given payload to given exchange' do
      expect(bunny_exchange_instance).to receive(:publish).with('some message', any_args).exactly(:once).times
      described_class.publish payload: 'some message', exchange: 'some'
    end

    context 'when connection closed' do
      let(:config) { EventBus::Configurator.config }
      let!(:connector) { EventBus::Connector.new(config) }

      it 'reconnect' do
        allow(connector).to receive(:check_connection!).
          and_raise(::EventBus::Connector::ConnectionClosedError.new)
        expect(connector).to receive(:check_connection!).twice
        expect(connector).to receive(:connect).once

        expect{described_class.send(:check_connection, connector)}.to(
          raise_error(::EventBus::Connector::ConnectionClosedError)
        )
      end
    end

    context 'when payload is not of allowed types' do

      it 'raises UnsupportedMessageType exception' do
        expect { described_class.publish payload: 1, exchange: 'some' }.to raise_error EventBus::Publisher::UnsupportedMessageType
      end
    end

    context 'when payload is one of allowed types' do

      it 'doesnt raise exception ' do
        [{some: :message}, ['some', 'message'], 'some message'].each do |msg|
          expect { described_class.publish payload: msg, exchange: 'some' }.not_to raise_error
        end
      end

    end

    context 'when exchange is not available' do
      it 'raises InvalidExchange exception' do
        expect { described_class.publish payload: 'test', exchange: 'other' }.to raise_error EventBus::Publisher::InvalidExchange
      end
    end

  end
end