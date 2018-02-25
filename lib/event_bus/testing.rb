require 'event_bus/publisher'
module EventBus
  module TestMethods
    def publish(payload:, exchange:)
      @exchanges ||= {}
      @exchanges[exchange] ||= []
      @exchanges[exchange].push validate_payload(payload)
    end
  end

  class Testing

    class << self

      def set_test_mode!(mode = :on)
        if mode == :on
          EventBus::Publisher.singleton_class.class_eval do
            alias_method :old_publish, :publish
            prepend EventBus::TestMethods
          end
        else
          EventBus::Publisher.singleton_class.class_eval do
            if defined?(:old_publish)
              alias_method :publish, :old_publish
              remove_method :old_publish
            end
          end
        end
      end

    end

  end
end