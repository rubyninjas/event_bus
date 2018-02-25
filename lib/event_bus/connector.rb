require 'bunny'

module EventBus
  class Connector
    include Configurator

    class ConnectionError < ::RuntimeError;
    end
    class ConnectionClosedError < ::RuntimeError;
    end
    class ChannelError < ::RuntimeError;
    end
    class ChannelClosedError < ::RuntimeError;
    end
    class ExchangeError < ::RuntimeError;
    end
    class QueueError < ::RuntimeError;
    end
    class ExchangeStateError < ::RuntimeError;
    end

    attr_accessor :connection, :channel, :exchanges, :config, :exchange_opts

    def initialize(config = Configurator.config)
      @exchanges     = {}.with_indifferent_access
      @config        = config
      @exchange_opts = config.exchange_opts
    end

    def connect
      set_up_connection
      check_connection!
    end

    def disconnect
      if @channel
        @channel.close if @channel.open?
        @channel = nil
      end
      if @connection
        @connection.close
        @connection = nil
      end
      @exchanges = {}.with_indifferent_access
    end

    def set_up_connection
      create_connection!
      open_channel!
      create_exchanges!
    end

    def create_connection!
      @connection = create_connection
      @connection.start
    end

    def open_channel!
      @channel = open_channel
    end

    def create_exchanges!
      config.exchanges.each_pair do |exchange_key, exchange_opts|
        @exchanges[exchange_key] = create_exchange(exchange_opts.name)
        create_queue
      end
    end

    def open_channel
      @connection.create_channel
    end

    def current_timestamp
      Time.now
    end

    def check_connection!
      raise ConnectionError, 'connection not exists' if connection.nil?
      raise ConnectionClosedError, 'connection is closed' unless connection.open?
      raise ChannelError, 'channel not exists' if channel.nil?
      raise ChannelClosedError, 'channel is closed' unless channel.open?
      raise ExchangeError if exchanges.empty?
      raise QueueError if exchanges.empty?
      exchanges.each_pair { |name, e| raise ExchangeStateError, "exchange[#{name}]: channel is closed" unless e.channel&.open? }
    end

    private

    def logger
      Configurator.logger
    end

    def create_exchange(exchange_name)
      logger.info "exchange_name=#{exchange_name}, type: #{exchange_opts.type}, durable: #{exchange_opts.durable}, arguments: #{exchange_opts.arguments.h}" rescue nil
      channel.exchange(exchange_name, exchange_opts.h.slice(:type, :direct, :durable, :auto_delete, :arguments))
    end

    def create_queue
      @channel.queue('mst.queue', exchange_opts.h.slice(:durable))
    end

    def create_connection
      ::Bunny.new(connection_settings, logger: logger)
    end

    def queues_healthy?
      raise ExchangeError if exchanges.empty?
      exchanges.each_pair do |_, ex|
        raise QueueError if ex.find_queue(ex.routing_key).nil?
      end
    end

  end
end
