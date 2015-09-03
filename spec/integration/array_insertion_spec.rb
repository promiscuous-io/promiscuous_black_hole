require 'spec_helper'

describe Promiscuous::BlackHole do
  before do
    class PublisherModel
      field :groups
      publish :groups
    end
  end

  it 'does not add the array if it is empty' do
    PublisherModel.create!(:groups => [])

    eventually do
      expect(DB.table_exists?(:'publisher_model$groups')).to eq(false)
    end
  end

  it 'generates a bson id for each array item' do
    PublisherModel.create!(:groups => ['Choice'])
    id = BSON::ObjectId.new
    allow(BSON::ObjectId).to receive(:new).and_return(id)
    eventually do
      expect(DB[:'publisher_model$groups'].first[:id]).to eq(id.to_s)
    end
  end

  it 'strips nil values from arrays before adding them' do
    PublisherModel.create!(:groups => ['Choice', nil])

    eventually do
      expect(extract_array('publisher_model', 'group')).to eq(['Choice'])
    end
  end

  it 'does not reject false booleans from arrays before adding them' do
    PublisherModel.create!(:groups => [false, true])

    eventually do
      expect(extract_array('publisher_model', 'group')).to eq([false, true])
    end
  end

  it 'escapes quotes in arrays before adding them' do
    PublisherModel.create!(:groups => ['I like to "party"'])

    eventually do
      expect(extract_array('publisher_model', 'group')).to eq(['I like to "party"'])
    end
  end

  it 'handles arrays with the date type' do
    PublisherModel.create!(:groups => ['2014-10-10'])

    eventually do
      expect(extract_array('publisher_model', 'group')).to eq([Date.new(2014, 10, 10)])
    end
  end

  it 'handles typed arrays on update' do
    PublisherModel.create!(:groups => ['2014-10-10'])
    PublisherModel.first.update_attributes!(:groups => ['2015-02-10'])

    eventually do
      expect(extract_array('publisher_model', 'group')).to eq([Date.new(2015, 2, 10)])
    end
  end

  it 'handles json arrays' do
    PublisherModel.create!(:groups => [{'keys' => 'and values'}, { 'more keys' => 'and values' }])

    eventually do
      expect(extract_array('publisher_model', 'group')).to eq(["{\"keys\":\"and values\"}", "{\"more keys\":\"and values\"}"])
    end
  end

  it 'removes old array values on updates' do
    PublisherModel.create!(:groups => ['2014-10-10', '2013-10-10', '2013-10-11'])
    PublisherModel.first.update_attributes!(:groups => ['2015-02-10'])

    eventually do
      expect(extract_array('publisher_model', 'group')).to eq([Date.new(2015, 2, 10)])
    end
  end

  it 'correctly handles complex table names' do
    define_constant :'PublisherModel::Base' do
      include Mongoid::Document
      include Promiscuous::Publisher
      field :groups
      publish :groups
    end

    PublisherModel::Base.create!(:groups => ['2014-10-10', '2013-10-10', '2013-10-11'])

    eventually do
      expect(DB.table_exists?(:'publisher_model$groups')).to eq(true)
    end
  end
end
