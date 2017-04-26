require_relative "event_transitions"

# Adds support for events when `extend`ed into state machine classes
module Statesman
  module Events
    def self.included(base)
      unless base.respond_to?(:states)
        raise "Statesman::Events included before/without Statesman::Machine"
      end
      base.extend(ClassMethods)
    end

    module ClassMethods
      def events
        @events ||= Hash.new do |events, event_name|
          events[event_name] = {
            transitions: {},
            callbacks: {
              before: [],
              after: [],
              after_commit: [],
              guards: [],
            }
          }
        end
      end

      def event(name, &block)
        EventTransitions.new(self, name, &block)
      end
    end

    def trigger!(event_name, metadata = {})
      transitions = self.class.events.fetch(event_name).fetch(:transitions) do
        raise Statesman::TransitionFailedError,
              "Event #{event_name} not found"
      end

      new_state = transitions.fetch(current_state) do
        raise Statesman::TransitionFailedError,
              "State #{current_state} not found for Event #{event_name}"
      end

      guards_for_event(event_name).each do |guard|
        unless guard.call(@object, last_transition, metadata)
          raise GuardFailedError,
                "Guard on event: #{event_name} with object: #{@object}" \
                + " metadata: #{metadata} returned false"
        end
      end

      transition_to!(new_state.first, metadata)
      true
    end

    def trigger(event_name, metadata = {})
      self.trigger!(event_name, metadata)
    rescue Statesman::TransitionFailedError, Statesman::GuardFailedError
      false
    end

    def available_events
      state = current_state
      self.class.events.select do |_, event|
        event[:transitions].key?(state)
      end.map(&:first)
    end

    def guards_for_event(event_name)
      self.class.events[event_name][:callbacks][:guards]
    end

    def can_trigger_event?(event_name, metadata = {})
      guards_for_event(event_name).all? do |guard|
        guard.call(@object, last_transition, metadata)
      end
    end
  end
end
