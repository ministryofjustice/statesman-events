module Statesman
  class EventTransitions
    attr_reader :machine, :event_name, :from, :to

    def initialize(machine, event_name, &block)
      @machine    = machine
      @event_name = event_name
      instance_eval(&block)
    end

    def transition(from: nil, to: nil)
      @from = to_s_or_nil(from)
      @to = array_to_s_or_nil(to)

      machine.transition(from: @from, to: @to)

      machine.events[event_name] ||= {}
      machine.events[event_name][@from] ||= []
      machine.events[event_name][@from] += @to
    end

    def before(&block)
      machine.before_transition(from: from, to: to) do |object, transition|
        block.call(event_name, object, transition)
      end
    end

    def after(&block)
      machine.after_transition(from: from, to: to) do |object, transition|
        block.call(event_name, object, transition)
      end
    end

    def guard(&block)
      machine.guard_transition(from: from, to: to) do |object, transition|
        block.call(event_name, object, transition)
      end
    end

    private

    def to_s_or_nil(input)
      input.nil? ? input : input.to_s
    end

    def array_to_s_or_nil(input)
      Array(input).map { |item| to_s_or_nil(item) }
    end
  end
end
