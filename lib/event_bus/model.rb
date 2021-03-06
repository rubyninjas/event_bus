require 'active_support/concern'
require 'active_record/transactions'
module EventBus
  module Model
    extend ActiveSupport::Concern

    class_methods do

      def event_bus_callback(fire_on:, condition:, exchange_hub:, message: nil)


        callback = ->(record) do
          payload = message || (yield(record) if block_given?)
          EventBus::Publisher.publish payload: payload,
                                      exchange: exchange_hub
        end

        args = [callback, { if: condition }]
        set_options_for_callbacks!(args, on: fire_on)
        set_callback :commit, :after, *args
      end

    end

    included do
      attr_accessor :was_deleted

      after_destroy -> {
        @was_deleted ||= {}
        @was_deleted[self.id] = true
      }
    end

  end
end
