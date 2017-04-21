require "spec_helper"

describe Statesman::EventTransitions do
  let(:machine) do
    Class.new do
      include Statesman::Machine
      include Statesman::Events
    end
  end
  let(:my_model) { Class.new { attr_accessor :current_state }.new }

  before do
    machine.class_eval do
      state :x, initial: true
      state :y
      state :z

      event :event_1 do
        transition from: :x, to: :y
      end

      event :event_2 do
        transition from: :y, to: :z
      end
    end
  end

  let(:instance) { machine.new(my_model) }

  describe '#guard' do
    before do
      machine.class_eval do
        state :foo
        state :bar
      end
    end

    context 'with no from or to states' do
      before do
        machine.class_eval do
          event :event_3 do
            transition from: :x, to: :foo
            transition from: :y, to: :foo
            guard { false }
          end
        end
      end

      it 'applies the guard to all event transitions' do
        expect { instance.trigger!(:event_3) }.
          to raise_error(Statesman::GuardFailedError)
        instance.trigger!(:event_1)
        expect { instance.trigger!(:event_3) }.
          to raise_error(Statesman::GuardFailedError)
      end
    end

    context 'with only a from state' do
      before do
        machine.class_eval do
          event :event_4 do
            transition from: :x, to: :foo
            transition from: :y, to: :foo
            guard(from: :x) { false }
          end
        end
      end

      it 'applies the guard to the indicated transition' do
        expect { instance.trigger!(:event_4) }.
          to raise_error(Statesman::GuardFailedError)
      end

      it 'does not apply the guard to the other transitions' do
        instance.trigger!(:event_1)
        instance.trigger!(:event_4)
      end
    end

    context 'with only a to state' do
      before do
        machine.class_eval do
          event :event_4 do
            transition from: :x, to: :y
          end
          event :event_5 do
            transition from: :x, to: :bar
            transition from: :y, to: :foo
            guard(to: 'foo') { false }
          end
        end
      end

      it 'applies the guard to the indicated transition' do
        instance.trigger!(:event_4)
        expect { instance.trigger!(:event_5) }.
          to raise_error(Statesman::GuardFailedError)
      end
    end
  end
end
