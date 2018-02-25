require 'spec_helper'
require 'event_bus/connector'
require 'event_bus/configurator'
require 'event_bus/publisher'

def expect_publish_event(expected_event_msg, called = :once)
  expect_any_instance_of(Bunny::Exchange).to receive(:publish).with(expected_event_msg, any_args).exactly(called).times
end

def expect_not_publish_event(declined_event_msg)
  expect_any_instance_of(Bunny::Exchange).not_to receive(:publish).with(declined_event_msg, any_args)
end

def expect_not_publish_event_any
  expect_any_instance_of(Bunny::Exchange).not_to receive(:publish).with(any_args)
end

RSpec.describe EventBus::Publisher do

  describe '#publish' do

    it 'publishes given payload to given exchange' do
      expect_publish_event 'some message'
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

    context 'when payload is oneof allowed types' do
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