module Statesman
  class EventTransitions
    attr_reader :machine, :event_name, :from, :to

    def initialize(machine, event_name, &block)
      @machine    = machine
      @event_name = event_name
      @before_transitions = {}
      @after_transitions  = {}
      @guard_transitions  = {}
      instance_eval(&block)

      all_transitions_matching(@before_transitions).each do |from, to, block|
        machine.before_transition(from: from, to: to) do |object, transition, options|
          block.call(object, transition, options)
        end
      end

      all_transitions_matching(@after_transitions).each do |from, to, block|
        machine.after_transition(from: from, to: to) do |object, transition, options|
          block.call(object, transition, options)
        end
      end

      all_transitions_matching(@guard_transitions).each do |from, to, block|
        machine.guard_transition(from: from, to: to) do |object, transition, options|
          block.call(object, transition, options)
        end
      end
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

      machine.events[event_name] ||= {}
      machine.events[event_name][@from] ||= []
      machine.events[event_name][@from] += @to
    end

    def before(&block)
      @before_transitions[[options[:from], options[:to]]] ||= []
      @before_transitions[[options[:from], options[:to]]] << block
    end

    def after(options = {}, &block)
      @after_transitions[[options[:from], options[:to]]] ||= []
      @after_transitions[[options[:from], options[:to]]] << block
    end

    def guard(options = {}, &block)
      @guard_transitions[[options[:from], options[:to]]] ||= []
      @guard_transitions[[options[:from], options[:to]]] << block
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
