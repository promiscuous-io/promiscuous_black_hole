require 'spec_helper'

describe Promiscuous::BlackHole do
  it 'caches embeddings within a message' do
    $calls = 0

    class Promiscuous::BlackHole::StaleEmbeddingsDestroyer
      alias_method :orig_fetch_child_tables, :fetch_child_tables
      def fetch_child_tables
        $calls += 1
        orig_fetch_child_tables
      end
    end

    class PublisherModel
      embeds_many :embedded_publishers
      publish :embedded_publishers
    end

    define_constant :EmbeddedPublisher do
      include Mongoid::Document
      include Promiscuous::Publisher
      embedded_in :publisher_model
      embeds_one :more_embedded_publisher
    end

    define_constant :MoreEmbeddedPublisher do
      include Mongoid::Document
      include Promiscuous::Publisher
      embedded_in :embedded_publisher
    end


    embedded_publishers = 50.times.map do |child|
      EmbeddedPublisher.new(:more_embedded_publisher => MoreEmbeddedPublisher.new)
    end
    m = PublisherModel.create!(:embedded_publishers => embedded_publishers)

    sleep 1

    m.update_attributes(:embedded_publishers => [EmbeddedPublisher.new])
    sleep 5
    p $calls
  end
end
