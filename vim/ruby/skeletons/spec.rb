# frozen_string_literal: true

require 'SUT'

RSpec.describe SUT do
  subject(:sut) { described_class.new }

  let(:anything) { 42 }

  describe '#instance_method' do
    it 'does sth' do
    end
  end

  describe '.class_method' do
    it 'does sth' do
    end

    context 'with sth' do
      it 'does sth else' do
      end
    end
  end
end
