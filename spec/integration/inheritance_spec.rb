require 'spec_helper'

describe Promiscuous::BlackHole do
  before do
    define_constant :InheritingModel, PublisherModel
  end

  it 'adds the record to the table for the top end of the inheritance chain' do
    InheritingModel.create!

    eventually do
      expect(DB[:publisher_models].count).to eq(1)
    end
  end

  it 'records _type as the bottom end of the inheritance chain' do
    InheritingModel.create!

    eventually do
      expect(DB[:publisher_models].first[:_type]).to eq('InheritingModel')
    end
  end
end
