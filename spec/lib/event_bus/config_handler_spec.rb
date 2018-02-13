require 'spec_helper'
require 'event_bus/config_handler'

RSpec.describe EventBus::ConfigHandler do
  let(:struct) { described_class.new({a: 1, b: {c: '2' } }) }

  context '#initialize' do
    it 'gets an hash', :aggregate_failures do
      expect(struct.keys).to match_array(%w[a b])
      expect(struct.a).to eq 1
    end
  end

  context '#accessors' do
    it 'gets an deep hash' do
      expect(struct.b).to be_an_instance_of described_class
    end
    it 'dig' do
      expect(struct.dig :b,:c).to eq '2'
    end
  end


end
