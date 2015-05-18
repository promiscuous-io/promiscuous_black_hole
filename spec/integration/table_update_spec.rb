require 'spec_helper'

describe Promiscuous::BlackHole do
  it 'creates a correctly named table' do
    expect(DB.table_exists?('publisher_models')).to eq(false)

    PublisherModel.create!

    sleep 0.1

    expect(DB.table_exists?('publisher_models')).to eq(true)
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
