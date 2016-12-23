require "spec_helper"

describe Statesman::EventTransitions do
  let(:machine) do
    Class.new do
      include Statesman::Machine
      include Statesman::Events

      state :x, initial: true
      state :y
    end
  end
  let(:my_model) { Class.new { attr_accessor :current_state }.new }
  let(:instance) { machine.new(my_model) }

  shared_examples(
    'a delegate to Statesman transitions'
  ) do |callback_type, passes_transition|
    delegatee = "#{callback_type}_transition"
    let(:event) do
      machine.class_eval do
        event :test_event do
          transition from: :x, to: :y
        end
      end
    end

    it "adds #{delegatee} callback to our event" do
      allow(machine).to receive(delegatee)

      event.instance_eval { send(callback_type) {} }

      expect(machine).to have_received(delegatee).
        once.with(from: 'x', to: ['y'])
    end

    it 'makes the event_name available to the block' do
      callback = ->(*_args) { nil }
      allow(callback).to receive(:call).and_return(true)
      event.instance_eval { send(callback_type, &callback) }

      instance.trigger! :test_event

      third_callback_arg = passes_transition ? instance.last_transition : nil
      expect(callback).to have_received(:call).
        with(:test_event, my_model, third_callback_arg)
    end
  end

  describe '#before' do
    it_behaves_like 'a delegate to Statesman transitions', 'before', true
  end

  describe '#after' do
    it_behaves_like 'a delegate to Statesman transitions', 'after', true
  end

  describe '#guard' do
    it_behaves_like 'a delegate to Statesman transitions', 'guard', false
  end
end
