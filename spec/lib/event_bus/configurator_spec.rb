require 'spec_helper'
require 'event_bus/connector'

RSpec.describe EventBus::Configurator, :rabbit do

  before do
    described_class.instance_variable_set(:@config, nil)
    described_class.instance
  end
  after do
    described_class.instance_variable_set(:@config, nil)
  end
  let(:config) { described_class.config }

  describe 'when default config' do
    it 'have exchange and publisher options', :aggregate_failures do
      expect(config.exchanges.count).to eq 2
      %i[connection exchanges exchange_opts].each do |arg|
        expect(config.respond_to? arg).to be_truthy
      end
      %i[routing_key delay].each do |arg|
        config.exchanges.each_pair { |_, publisher| expect(publisher.respond_to? arg).to be_truthy }
      end
      %i[type durable auto_delete mandatory arguments content_type].each do |arg|
        expect(config.exchange_opts.respond_to? arg).to be_truthy
      end
    end
  end

  describe 'init config from file' do
    let(:cfg) { YAML::load_file(File.expand_path(Dir.pwd) + '/spec/fixtures/rabbitmq.test.yml')['test'] }

    it 'loads config', :aggregate_failures do
      described_class.instance(cfg)
      connection = described_class.config.connection
      expect(connection.host).to eq '127.0.0.130'
      expect(connection.port).to eq 9876
      expect(connection.user).to eq 'user'
      expect(connection.pass).to eq 'password'
    end
  end
end
