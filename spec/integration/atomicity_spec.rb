require 'spec_helper'

describe Promiscuous::BlackHole do
  it 'processes each record atomically in one transaction' do
    class PublisherModel
      embeds_many :embedded_publishers
      publish :embedded_publishers
    end

    define_constant :EmbeddedPublisher do
      include Mongoid::Document
      include Promiscuous::Publisher
      embedded_in :publisher_model

      field :field_1
      publish :field_1
    end

    PublisherModel.create!(:group => 4, :embedded_publishers => [EmbeddedPublisher.new(:field_1 => 3)])

    # ensure that enough time passes to ensure that the above message is processed first
    sleep 0.2

    # breaks the schema for the embedded record's table
    PublisherModel.create!(:group => 3, :embedded_publishers => [EmbeddedPublisher.new(:field_1 => 'not a number')])


    eventually do
      expect(DB[:publisher_models].count).to eq(1)
    end
  end
end
