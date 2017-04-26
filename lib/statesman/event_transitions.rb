module Statesman
  class EventTransitions
    attr_reader :machine, :event_name, :from, :to

    def initialize(machine, event_name, &block)
      @machine    = machine
      @event_name = event_name
      instance_eval(&block)
    end

    def all_transitions_matching(transition_mappings)
      event_transitions = machine.events[@event_name]
      transition_mappings.map do |transitions, block|
        from_states = [transitions.first].flatten.compact
        to_states = [transitions.last].flatten.compact
        if from_states.empty? && to_states.empty?
          event_transitions.map do |from, to|
            [from].product(to, block)
          end .flatten(1)
        elsif from_states.empty?
          to_states.map do |to|
            event_transitions.to_a.
              find_all { |_, t| t.include? to }.
              map      { |f, _| [f].product([to], block) }.
              flatten(1)
          end .flatten(1)
        elsif to_states.empty?
          from_states.product(event_transitions[from], block)
        else
          from_states.product(to_states, block)
        end
      end .flatten(1)
    end

    def transition(from: nil, to: nil)
      @from = to_s_or_nil(from)
      @to = array_to_s_or_nil(to)

      machine.transition(from: @from, to: @to)

      machine.events[event_name][:transitions][@from] ||= []
      machine.events[event_name][:transitions][@from] += @to
    end

    def guard(&block)
      add_callback(callback_type: :guards, &block)
    end

    private

    def add_callback(callback_type: nil, &block)
      validate_callback_type_and_class(callback_type)

      machine.events[event_name][:callbacks][callback_type] << block
    end

    def validate_callback_type_and_class(callback_type)
      if callback_type.nil?
        raise ArgumentError.new("missing keyword: callback_type")
      end
    end

    def to_s_or_nil(input)
      input.nil? ? input : input.to_s
    end

    def array_to_s_or_nil(input)
      Array(input).map { |item| to_s_or_nil(item) }
    end
  end
end
