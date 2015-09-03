require 'spec_helper'

describe Promiscuous::BlackHole do
  it 'inserts json fields as strings' do
    PublisherModel.create!(:group => {:some => :json })
    eventually do
      expect(DB[:publisher_models].first[:group]).to eq("{\"some\":\"json\"}")
    end
  end
end
