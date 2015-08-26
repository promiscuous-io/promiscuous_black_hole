require 'spec_helper'

describe Promiscuous::BlackHole do
  context 'when a message creates a new table' do
    before do
      PublisherModel.create!
    end

    it 'creates default columns' do
      eventually do
        columns = schema_hash_for(:publisher_models)

        expected_columns = {
          :_v    => { :db_type => 'bigint' },
          :id    => { :db_type => 'character(24)', :primary_key => true },
          :_type => { :db_type => 'character varying(255)' }
        }

        expected_columns.each do |column_name, attrs|
          expect(columns[column_name]).to include(attrs)
        end
      end
    end

    it 'creates an index on _type' do
      eventually do
        index_attrs = {:columns => [:_type], :unique => false, :deferrable=>nil}
        indexes     = DB.indexes(:publisher_models).values

        expect(indexes).to include(index_attrs)
      end
    end
  end

  context 'when a new field ends in _id' do
    before do
      PublisherModel.create!(:other_collection_id => BSON::ObjectId.new)
    end

    it 'adds a char(24) column to the table' do
      eventually do
        column = schema_hash_for(:publisher_models)[:other_collection_id]

        expect(column[:db_type]).to eq('character(24)')
      end
    end

    it 'creates an index on the column' do
      eventually do
        index_attrs = {:columns => [:other_collection_id], :unique => false, :deferrable=>nil}
        indexes = DB.indexes(:publisher_models).values

        expect(indexes).to include(index_attrs)
      end
    end
  end

  context 'when a new fiend ends in _id but is not a BSON' do
    it 'correctly type casts strings' do
      PublisherModel.create!(:other_collection_id => 'abcd_1234')

      eventually do
        column = schema_hash_for(:publisher_models)[:other_collection_id]

        expect(column[:db_type]).to eq('text')
      end
    end

    it 'correctly type casts json' do
      PublisherModel.create!(:other_collection_id => { :id => 'hi this is dumb'})

      eventually do
        column = schema_hash_for(:publisher_models)[:other_collection_id]

        expect(column[:db_type]).to eq('json')
      end
    end
  end

  context 'when a new field is a number' do
    it_should_behave_like 'adding a column' do
      let(:input_value)      { 3 }
      let(:expected_db_type) { 'double precision' }
      let(:indexed)          { false }
    end
  end

  context 'when a new field is a boolean value' do
    it_should_behave_like 'adding a column' do
      let(:input_value)      { false }
      let(:expected_db_type) { 'boolean' }
      let(:indexed)          { false }
    end
  end

  context 'when a new field is a string' do
    context 'when it looks like a datetime' do
      datetime_strs = [
        '2011-01-20 19:35:48.431357',
        '2014-01-01T00:00:00.000-05:00',
        '2011-01-07T20:18:08Z'
      ]

      datetime_strs.each do |datetime_str|
        it_should_behave_like 'adding a column' do
          let(:input_value)      { datetime_str }
          let(:expected_db_type) { 'timestamp with time zone' }
          let(:indexed)          { true }
        end
      end
    end

    context 'when it looks like date' do
      it_should_behave_like 'adding a column' do
        let(:input_value)      { '2014-10-10' }
        let(:expected_db_type) { 'date' }
        let(:indexed)          { true }
      end
    end

    it_should_behave_like 'adding a column' do
      let(:input_value)      { 'just some text' }
      let(:expected_db_type) { 'text' }
      let(:indexed)          { false }
    end
  end

  context 'when a new field is json' do
    it_should_behave_like 'adding a column' do
      let(:input_value)      { { :some => { :crazy => :hash } } }
      let(:expected_db_type) { 'json' }
      let(:indexed)          { false }
    end
  end
end
