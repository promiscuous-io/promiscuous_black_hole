require 'spec_helper'

describe Promiscuous::BlackHole do
  context 'when receiving a message with a create or update operation' do
    let(:setup_singleton_publisher) do
      class PublisherModel
        # Overwrite _id to always return the same id
        field :_id, :overwrite => true, :default => BSON::ObjectId.new
      end

      # create table and record in db
      DB.create_table(:publisher_models) do
        column :id, :char, :primary_key => true, :size => 24
        column :_v, :bigint
        column :_type, :varchar, :size => 255
        column :group, :text
      end
    end

    it 'creates the record if there is no existing document' do
      PublisherModel.create!(:group => 3)
      PublisherModel.create!(:group => 2)

      eventually do
        expect(DB[:publisher_models].count).to eq(2)
      end
    end

    it 'updates the record if it has a higher version than the persisted document' do
      PublisherModel.create!(:group => 'v1 data')

      eventually do
        expect(DB[:publisher_models].first[:group]).to eq('v1 data')
        expect(DB[:publisher_models].first[:_v]).to eq(1)
      end

      PublisherModel.last.update_attributes!(:group => 'v2 data')

      eventually do
        expect(DB[:publisher_models].first[:group]).to eq('v2 data')
        expect(DB[:publisher_models].first[:_v]).to eq(2)
      end
    end

    it 'updates the record if it has the same version as the persisted document' do
      setup_singleton_publisher
      attrs = {'id' => PublisherModel.new.id.to_s, 'group' => 'expected data', '_v' => 1 }
      Promiscuous::BlackHole::Record.new('publisher_models', attrs).upsert

      expect(DB[:publisher_models].count).to eq(1)
      PublisherModel.new(:group => 'overwrite group').save!

      eventually do
        expect(DB[:publisher_models].count).to eq(1)
        expect(DB[:publisher_models].first[:group]).to eq('overwrite group')
        expect(DB[:publisher_models].first[:_v]).to eq(1)
      end
    end

    it 'updates the record if the persisted document has a null version' do
      setup_singleton_publisher
      attrs = {'id' => PublisherModel.new.id.to_s, 'group' => 'expected data', '_v' => nil }
      Promiscuous::BlackHole::Record.new('publisher_models', attrs).upsert

      expect(DB[:publisher_models].count).to eq(1)
      PublisherModel.new(:group => 'overwrite group').save!

      eventually do
        expect(DB[:publisher_models].count).to eq(1)
        expect(DB[:publisher_models].first[:_v]).to eq(1)
        expect(DB[:publisher_models].first[:group]).to eq('overwrite group')
      end
    end

    it 'ignores the record if the persisted document has a higher version' do
      setup_singleton_publisher
      attrs = {'id' => PublisherModel.new.id.to_s, 'group' => 'expected data', '_v' => 2 }
      Promiscuous::BlackHole::Record.new('publisher_models', attrs).upsert

      expect(DB[:publisher_models].count).to eq(1)

      @error = false
      use_real_backend { |config| config.error_notifier = proc { @error = true } }
      PublisherModel.new(:group => 'should not overwrite').save!

      sleep 0.2

      expect(DB[:publisher_models].count).to eq(1)
      expect(DB[:publisher_models].first[:group]).to eq('expected data')
      expect(@error).to eq(false)
    end
  end

  context 'when receiving a message with a delete operation' do
    before do
      Promiscuous::Config.destroy_timeout = 1.second
      m = PublisherModel.create!(:group => 3)
      m.destroy
    end

    it 'does not delete the record immediately' do
      sleep 0.2
      expect(DB[:publisher_models].count).to eq(1)
    end

    it 'deletes the record after a timeout' do
      eventually do
        expect(DB[:publisher_models].count).to eq(0)
      end
    end
  end
end
