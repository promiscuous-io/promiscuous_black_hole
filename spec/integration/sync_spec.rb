require 'spec_helper'

describe Promiscuous::BlackHole do
  before do
    without_promiscuous { PublisherModel.create!(:group => 3) }
  end

  it 'processes records synced to __all__' do
    PublisherModel.first.promiscuous.sync(Promiscuous::Config.sync_all_routing)

    eventually do
      expect(DB[:publisher_models].count).to eq(1)
    end
  end

  it 'processes records synced to the app' do
    PublisherModel.first.promiscuous.sync(Promiscuous::Config.app)

    eventually do
      expect(DB[:publisher_models].count).to eq(1)
    end
  end

  it 'does not process records synced to a different app' do
    PublisherModel.first.promiscuous.sync(:some_other_app)

    sleep 0.2

    expect(DB.table_exists?(:publisher_models)).to eq(false)
  end
end
