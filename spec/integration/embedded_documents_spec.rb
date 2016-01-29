require 'spec_helper'

describe Promiscuous::BlackHole do
  before do
    class PublisherModel
      embeds_many :embedded_publishers
      publish :embedded_publishers
    end

    define_constant :EmbeddedPublisher do
      include Mongoid::Document
      include Promiscuous::Publisher
      embedded_in :publisher_model
      embeds_one :more_embedded_publisher

      field :field_1
      publish :field_1, :more_embedded_publisher
    end

    define_constant :MoreEmbeddedPublisher do
      include Mongoid::Document
      include Promiscuous::Publisher
      embedded_in :embedded_publisher
    end
  end

  let(:embedded_publishers) do
    more_embedded_publisher = MoreEmbeddedPublisher.new

    [
      EmbeddedPublisher.new(:field_1 => 3),
      EmbeddedPublisher.new(:field_1 => 4, :more_embedded_publisher => more_embedded_publisher)
    ]
  end

  let!(:parent_model) { PublisherModel.create!(:embedded_publishers => embedded_publishers) }

  context 'when a parent record is created or updated' do
    it 'creates a new table for each new collection of embedded docs' do
      eventually do
        expect(DB.table_exists?(:embedded_publishers)).to eq(true)
        expect(DB.table_exists?(:more_embedded_publishers)).to eq(true)
      end
    end

    it 'persists the right data' do
      eventually do
        expect(DB[:embedded_publishers].to_a).to eq([
          {
            :id                => parent_model.embedded_publishers.first.id.to_s,
            :_v                => nil,
            :_type             => "EmbeddedPublisher",
            :field_1           => 3.0,
            :embedded_in_id    => parent_model.id.to_s,
            :embedded_in_table => "publisher_models"
          },
          {
            :id                => parent_model.embedded_publishers.second.id.to_s,
            :_v                => nil,
            :_type             => "EmbeddedPublisher",
            :field_1           => 4.0,
            :embedded_in_id    => parent_model.id.to_s,
            :embedded_in_table => "publisher_models"
          }
        ])

        expect(DB[:more_embedded_publishers].to_a).to eq([
          {
            :id                => parent_model.embedded_publishers.second.more_embedded_publisher.id.to_s,
            :_v                => nil,
            :_type             => "MoreEmbeddedPublisher",
            :embedded_in_id    => parent_model.embedded_publishers.second.id.to_s,
            :embedded_in_table => "embedded_publishers"
          }
        ])
      end
    end

    it 'does not mark updated embedded docs deleted when in soft delete mode' do
      Promiscuous::BlackHole::Config.delete_mode = :soft
      deleted_embedded_id = parent_model.embedded_publishers.second.id
      parent_model.embedded_publishers = [parent_model.embedded_publishers.first]
      parent_model.save!

      eventually do
        expect(DB[:embedded_publishers].to_a).to match_array([
          {
            :id => parent_model.embedded_publishers.first.id.to_s,
            :_v => nil,
            :_type => "EmbeddedPublisher",
            :field_1 => 3.0,
            :embedded_in_id => parent_model.id.to_s,
            :embedded_in_table => "publisher_models",
            :_deleted => false
          },
          {
            :id => deleted_embedded_id.to_s,
            :_v => nil,
            :_type => "EmbeddedPublisher",
            :field_1 => 4.0,
            :embedded_in_id => parent_model.id.to_s,
            :embedded_in_table => "publisher_models",
            :_deleted => true
          }
        ])
      end
    end

    it 'removes existing embedded records when the parent record is published' do
      parent_model.update_attributes!(:embedded_publishers => [])

      eventually do
        # create a record not associated with the parent, which should not be
        # deleted
        Promiscuous::BlackHole::Record.new('embedded_publishers', { :id => BSON::ObjectId.new.to_s }).upsert
      end

      eventually do
        expect(DB[:embedded_publishers].count).to eq(1)
        expect(DB[:more_embedded_publishers].count).to eq(0)
      end
    end

    it 'ignores out of order updates to embedded documents' do
      class PublisherModel
        # Overwrite _id to always return the same id
        field :_id, :overwrite => true, :default => BSON::ObjectId.new
      end

      attrs = {'id' => PublisherModel.new.id.to_s, '_v' => 2 }
      eventually do
        Promiscuous::BlackHole::Record.new('publisher_models', attrs).upsert
      end

      PublisherModel.create!(:embedded_publishers => [ EmbeddedPublisher.new(:field_1 => 3)])

      sleep 0.2

      expect(DB[:embedded_publishers].where('embedded_in_id = ?', attrs['id']).count).to eq(0)
    end
  end

  context 'when a parent record is deleted' do
    context 'when configured for hard deletes' do
      it 'removes any records embedded in the document' do
        PublisherModel.first.destroy

        eventually do
          expect(DB[:embedded_publishers].count).to eq(0)
          expect(DB[:more_embedded_publishers].count).to eq(0)
        end
      end
    end

    context 'when configured for soft deletes' do
      it 'marks embedded documents deleted' do
        Promiscuous::BlackHole::Config.delete_mode = :soft
        PublisherModel.first.destroy

        eventually do
          expect(DB[:embedded_publishers].first[:_deleted]).to eq(true)
          expect(DB[:more_embedded_publishers].first[:_deleted]).to eq(true)
        end
      end
    end
  end
end
