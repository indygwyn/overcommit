require 'spec_helper'

describe Overcommit::GitHook::BaseHook do
  describe '#initialize' do
    context 'with no plugins' do
      it 'initializes' do
        expect { subject }.to_not raise_error
      end
    end
  end

  describe '#run' do
    context 'with no hooks registered' do
      it 'does not raise' do
        expect { subject.run }.to_not raise_error
      end
    end

    context 'with a hook registered' do
      class DummyHook < Overcommit::GitHook::HookSpecificCheck
      end

      let!(:hook) { DummyHook.new }

      before do
        subject.stub(:registered_checks).and_return([DummyHook])
        DummyHook.stub(:new).and_return hook
      end

      context 'when not skipping' do
        before do
          hook.stub(:skip?).and_return false
        end

        it 'runs the hook' do
          hook.should_receive(:run_check)
          subject.run
        end
      end

      context 'when the hook wants to `skip?`' do
        before do
          hook.stub(:skip?).and_return true
        end

        it 'does not run the check' do
          hook.should_not_receive(:run_check)
          subject.run
        end
      end
    end

    context 'with a required hook registered' do
      class RequiredHook < Overcommit::GitHook::HookSpecificCheck
        include Overcommit::GitHook::HookRegistry
        required!
      end

      # This one will be skipped via the environment variable
      class OptionalHook < Overcommit::GitHook::HookSpecificCheck
        include Overcommit::GitHook::HookRegistry
      end

      let!(:required_hook) { RequiredHook.new }
      let!(:optional_hook) { OptionalHook.new }

      before do
        @old_skip = ENV['SKIP_CHECKS']
        ENV['SKIP_CHECKS'] = 'all'
        RequiredHook.stub(:new).and_return(required_hook)
        OptionalHook.stub(:new).and_return(optional_hook)
      end

      after do
        ENV['SKIP_CHECKS'] = @old_skip
      end

      it 'runs the required hook' do
        required_hook.should_receive(:run_check)
        subject.run
      end

      it 'skips the non-required hook' do
        optional_hook.should_not_receive(:run_check)
        subject.run
      end
    end
  end
end
