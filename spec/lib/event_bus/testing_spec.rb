require 'spec_helper'
require 'event_bus/testing'

RSpec.describe EventBus::Testing do
  let(:klass){ EventBus::Publisher }

  let!(:bunny_exchange_class){ class_double(Bunny::Exchange).as_stubbed_const }
  let!(:bunny_exchange_instance){ instance_double(Bunny::Exchange) }

  before do
    allow_any_instance_of(EventBus::Connector).to receive(:connect)
    allow_any_instance_of(EventBus::Connector).to receive(:check_connection!)
    allow_any_instance_of(EventBus::Connector).to receive(:exchanges).and_return({'some' => bunny_exchange_instance})

    allow(bunny_exchange_instance).to receive(:publish).and_return(:fired)

    described_class.set_test_mode!
    klass.exchanges&.clear
  end

  context 'when enabled' do

    after do
      described_class.set_test_mode!(:off)
    end

    it 'aliases EventBus::Publisher.publish with old_publish' do
      expect(klass.respond_to?(:old_publish)).to be_truthy
      expect(klass.method(:old_publish) == klass.method(:publish)).to be_falsey
      expect(klass.respond_to?(:exchanges)).to be_truthy
    end

    it 'redefines EventBus::Publisher.publish so it doesnt send to Bunny' do
      allow_any_instance_of(Bunny::Exchange).to receive(:publish).with(any_args).and_return(:fired)
      expect(klass.publish(exchange: 'some', payload: 'text')).not_to eq(:fired)
    end

    it 'saves given message to given exchange key' do
      klass.publish(exchange: 'some', payload: 'text1')
      klass.publish(exchange: 'some', payload: {other_msg: 'text2'})
      expect(klass.exchanges['some']).to match_array ['text1', { other_msg: 'text2' }.to_json.to_s ]
    end
  end

  context 'when disabled' do
    before{ described_class.set_test_mode!; described_class.set_test_mode!(:off); klass }

    it 'removes EventBus::Publisher.old_publish' do
      expect(klass.respond_to?(:old_publish)).to be_falsey
    end

    it 'reverts EventBus::Publisher.publish so it sends to Bunny' do
      expect(bunny_exchange_instance).to receive(:publish).with(any_args).and_return(:fired)
      expect(klass.publish(exchange: 'some', payload: 'text')).to eq :fired
    end

  end
end