require 'spec_helper'

describe Promiscuous::BlackHole do
  it 'creates a correctly named table' do
    expect(DB.table_exists?('publisher_models')).to eq(false)

    PublisherModel.create!

    sleep 0.1

    expect(DB.table_exists?('publisher_models')).to eq(true)
  end

  it 'handles table names longer than max_identifier_length' do
    max_identifier_length = DB.fetch('show max_identifier_length').first[:max_identifier_length].to_i
    long_table_name = "Longname" + "c" * (max_identifier_length)
    define_constant long_table_name do
      include Mongoid::Document
      include Promiscuous::Publisher
      field :a
      publish :a
    end

    model = long_table_name.constantize

    model.create!(:a => 1)
    model.create!(:a => 2)

    expected_table_name = long_table_name.downcase[0...max_identifier_length - 1]

    sleep 0.2

    expect(DB.table_exists?(expected_table_name)).to eq(true)
    expect(DB[expected_table_name].select_map(:a)).to eq([1, 2])
  end

  it 'replaces :: with _ in naming the table' do
    expect(DB.table_exists?('hockey_goals')).to eq(false)

    define_constant :'Hockey::Goal' do
      include Mongoid::Document
      include Promiscuous::Publisher
    end

    Hockey::Goal.create!

    sleep 0.1

    expect(DB.table_exists?('hockey_goals')).to eq(true)
  end

  it 'strips ::Base from namespaced models' do
    expect(DB.table_exists?('publisher_models')).to eq(false)

    define_constant :'PublisherModel::Base' do
      include Mongoid::Document
      include Promiscuous::Publisher
    end

    PublisherModel::Base.create!

    sleep 0.1

    expect(DB.table_exists?('publisher_models')).to eq(true)
  end
end
