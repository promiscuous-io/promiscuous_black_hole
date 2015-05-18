require 'spec_helper'

describe Promiscuous::BlackHole do
  before do
    PublisherModel.create!(:group => {:some => :json })
  end

  it 'inserts json fields correctly' do
    eventually do
      expect(DB[:publisher_models].first[:group]).to eq('some' => 'json')
    end
  end

  it 'updates json fields correctly' do
    PublisherModel.first.update_attributes!(:group => {:newer => :json })

    eventually do
      expect(DB[:publisher_models].first[:group]).to eq('newer' => 'json')
    end
  end
end
