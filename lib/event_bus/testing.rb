require 'event_bus/publisher'
module EventBus
  module TestMethods

    def self.included(base)
      base.class_eval do
        alias_method :old_publish, :publish
        undef_method :publish

        def publish(payload:, exchange:)
          puts 'EventBus::Publisher.publish is mocked'
          @exchanges ||= {}
          @exchanges[exchange] ||= []
          @exchanges[exchange].push validate_payload(payload)
        end

        def exchanges
          @exchanges
        end

      end
    end

  end

  class Testing

    class << self

      def set_test_mode!(mode = :on)
        if mode == :on
          EventBus::Publisher.singleton_class.class_eval do
            unless instance_methods.include?(:old_publish)
              include EventBus::TestMethods
            end
          end
        else
          EventBus::Publisher.singleton_class.class_eval do
            if instance_methods.include?(:old_publish)
              alias_method :publish, :old_publish
              undef_method :old_publish
            end
            if instance_methods.include?(:exchanges)
              undef_method :exchanges
            end
          end
        end
      end

    end

  end
end