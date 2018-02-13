require 'yaml'
require 'hashie'

module EventBus
  module Configurator
    module_function

    def instance(cfg = {})
      @config  = default_config.with_indifferent_access
      file_cfg = YAML::load_file(config_path)[environment]
      @config.deep_merge!(file_cfg) if file_cfg
      @config.deep_merge!(cfg)
      @config = EventBus::ConfigHandler.new @config
      @config
    end

    def default_config
      {
        exchange_opts: {
          type:        'x-delayed-message',
          durable:     true,
          auto_delete: false,
          mandatory:   false, #no mandatory acknolegement confirmation
          arguments:    { 'x-delayed-type' => 'fanout' },
          content_type: 'application/json'
        }
      }
    end

    def config
      return @config unless @config.nil?
      instance
    end

    def connection_settings
      config&.connection&.slice(:host, :port, :user, :pass)
    end

    def environment
      @environment ||= defined?(Rails) ? Rails.env : (ENV['RAILS_ENV'] || ENV['RACK_ENV'])
    end

    def config_path
      @config_path ||= if defined?(Rails)
                         Rails.root.join('config', 'rabbitmq.yml')
                       else
                         if environment != 'test'
                           File.expand_path(Dir.pwd) + '/config/rabbitmq.yml'
                         else
                           File.expand_path(Dir.pwd) + '/spec/fixtures/rabbitmq.default.test.yml'
                         end
                       end
    end
  end
end
