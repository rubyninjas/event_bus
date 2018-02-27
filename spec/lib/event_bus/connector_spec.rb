require 'spec_helper'
require 'event_bus/connector'
require 'event_bus/configurator'
require 'active_support/core_ext/hash/deep_merge'

RSpec.describe EventBus::Connector do
  let!(:connector) { described_class.new }

  before do
    bunny_session = double('session').as_null_object
    allow(Bunny).to receive(:new).and_return(bunny_session)
  end

  describe '#connect' do

    it 'sets up connection' do
      expect(connector).to receive(:set_up_connection)
      expect(connector).to receive(:check_connection!)
      connector.connect
    end

    it 'does not disconnect' do
      expect(connector).not_to receive(:disconnect)
      connector.connect
    end

  end

  describe '#set_up_connection' do
    it 'creates connection, channel, exchange' do
      expect(connector).to receive(:create_connection!)
      expect(connector).to receive(:open_channel!)
      expect(connector).to receive(:create_exchanges!)

      connector.set_up_connection
    end
  end

  describe '#create_connection!' do
    it 'sets the #connection to #create_connection', :aggregate_failures do
      connection = double('connection').as_null_object
      expect(connector).to receive(:create_connection).and_return(connection)
      connector.create_connection!
      expect(connector.connection).to eq(connection)
    end
  end

  describe '#exchanges' do
    it 'saves created exchanges to hash' do
      connector.connect
      expect(connector.exchanges.keys).to match_array %w(some some_other)
    end
  end

  context 'raise errors' do

    it 'in cases' do
      connector.disconnect
      expect { connector.check_connection! }.to raise_exception(described_class::ConnectionError)

      connector.create_connection!
      expect { connector.check_connection! }.to raise_exception(described_class::ChannelError)

      connector.open_channel!
      expect { connector.check_connection! }.to raise_exception(described_class::ExchangeError)
    end

  end


end
