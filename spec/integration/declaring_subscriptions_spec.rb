require 'spec_helper'

describe Promiscuous::BlackHole do
  around(:each) do |example|
    subscriptions_was = Promiscuous::BlackHole::Config.subscriptions
    example.run
    Promiscuous::BlackHole::Config.subscriptions = subscriptions_was
  end

  it 'subscribes to all collections when Config.subscriptions == :__all__' do
    Promiscuous::BlackHole::Config.subscriptions = :__all__
    PublisherModel.create!

    eventually do
      expect(DB.table_exists?('publisher_models')).to eq(true)
    end
  end

  it 'subscribes to collections specified by Config.subscriptions' do
    Promiscuous::BlackHole::Config.subscriptions = [:PublisherModel]
    PublisherModel.create!

    eventually do
      expect(DB.table_exists?('publisher_models')).to eq(true)
    end
  end

  it 'subscribes to collections whose base class are specified by Config.subscriptions' do
    define_constant :InheritingModel, PublisherModel
    Promiscuous::BlackHole::Config.subscriptions = [:PublisherModel]
    InheritingModel.create!

    eventually do
      expect(DB.table_exists?('publisher_models')).to eq(true)
    end
  end

  it 'does not subscribe to collections not specified by Config.subscriptions' do
    Promiscuous::BlackHole::Config.subscriptions = [:OtherModel]
    PublisherModel.create!

    sleep 0.2

    expect(DB.table_exists?('publisher_models')).to eq(false)
  end
end
