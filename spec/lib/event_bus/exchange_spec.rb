require 'spec_helper'

RSpec.describe EventBus::Connector do
  before do
    @config = EventBus::Configurator.config
  end

  after do
    EventBus::Configurator.instance_variable_set(:@config, nil)
    EventBus::Configurator.instance
  end

  let!(:connector) { EventBus::Connector.new(@config) }

  before :each do
    connector.connect
  end
  after :each do
    connector.disconnect
  end

  context "of type 'x-delayed-message'" do

    context 'with a custom name' do
      it 'is declared' do
        ch = connector.channel

        name = "bunny.tests.exchanges.x-delayed-message.fanout#{rand}"
        x    = ch.exchange(name, type: 'x-delayed-message', arguments: { 'x-delayed-type' => 'fanout' })
        expect(x.name).to eq name

        x.delete
        ch.close
      end
    end

    context 'with a configured names', :aggregates_failures do
      it 'is declared' do
        ch = connector.channel
        xx = ch.exchanges
        expect(xx.keys).to match_array %w(mst.some.test mst.some.other.test)
      end
    end

  end

end
