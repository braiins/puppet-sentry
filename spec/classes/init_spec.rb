require 'spec_helper'
describe 'sentry' do

  context 'with defaults for all parameters' do
    it { should contain_class('sentry') }
  end
end
