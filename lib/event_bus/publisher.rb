require 'active_support/core_ext/class/attribute_accessors'

module EventBus
  class Publisher

    mattr_reader :connector

    class InvalidExchange < RuntimeError
      def initialize(exchange)
        super "Invalid exchange given: #{exchange}"
      end
    end

    class UnsupportedMessageType < StandardError
      def initialize(kls)
        super "Unsupported message type: #{kls}"
      end
    end

    class << self

      def publish(payload:, exchange:)
        @connector ||= define_connector
        check_connection(@connector)

        logger.debug "Publisher##{payload}"
        message = validate_payload(payload)
        push_to_exchange(exchange, message, get_exchange_opts(exchange))
      end

      private

      def logger
        Configurator.logger
      end

      def check_connection(connector)
        connector.check_connection!
      rescue ::EventBus::Connector::ConnectionClosedError
        connector.connect
        connector.check_connection!
      end

      def validate_payload(payload)
        case payload
          when Hash, Array then payload.to_json.to_s
          when String then payload
          else raise(UnsupportedMessageType.new(payload.class.name))
        end
      end

      def push_to_exchange(exchange, message, opts)
        @connector.exchanges[exchange].publish(message, opts)
      end

      def get_exchange_opts(exchange)
        @connector.config.exchanges[exchange]&.h&.deep_symbolize_keys || raise(InvalidExchange.new(exchange))
      end

      def define_connector
        Thread.current[:bunny_connector] ||= Connector.new
        Thread.current[:bunny_connector].connect
        Thread.current[:bunny_connector]
      end

    end
  end
end