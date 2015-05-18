require 'spec_helper'

describe Promiscuous::BlackHole do
  it 'does not add the array if it is empty' do
    PublisherModel.create!(:group => [])

    eventually do
      expect(DB[:publisher_models].first.keys).to_not include(:group)
    end
  end

  it 'strips nil values from arrays before adding them' do
    PublisherModel.create!(:group => ['Choice', nil])

    eventually do
      expect(DB[:publisher_models].first[:group]).to eq(['Choice'])
    end
  end

  it 'does not reject false booleans from arrays before adding them' do
    PublisherModel.create!(:group => [false, true])

    eventually do
      expect(DB[:publisher_models].first[:group]).to eq([false, true])
    end
  end

  it 'escapes quotes in arrays before adding them' do
    PublisherModel.create!(:group => ['I like to "party"'])

    eventually do
      expect(DB[:publisher_models].first[:group]).to eq(['I like to "party"'])
    end
  end

  it 'handles arrays with the date type' do
    PublisherModel.create!(:group => ['2014-10-10'])

    eventually do
      expect(DB[:publisher_models].first[:group]).to eq([Date.new(2014, 10, 10)])
    end
  end

  it 'handles typed arrays on update' do
    PublisherModel.create!(:group => ['2014-10-10'])
    PublisherModel.first.update_attributes!(:group => ['2015-02-10'])

    eventually do
      expect(DB[:publisher_models].first[:group]).to eq([Date.new(2015, 2, 10)])
    end
  end

  it 'handles json arrays' do
    PublisherModel.create!(:group => [{'keys' => 'and values'}, { 'more keys' => 'and values' }])

    eventually do
      expect(DB[:publisher_models].first[:group]).to eq("{\"{\\\"keys\\\":\\\"and values\\\"}\",\"{\\\"more keys\\\":\\\"and values\\\"}\"}")
    end
  end
end
