require 'spec_helper'

RSpec.describe EventBus do
  it 'has a version number' do
    expect(EventBus::VERSION).not_to be nil
  end
end
