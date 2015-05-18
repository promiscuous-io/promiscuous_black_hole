module Promiscuous::BlackHole
  class EmbeddedMessage < Message
    def self.embedded_value?(value)
      value.kind_of?(Hash) && (
        value['types'] == ['Promiscuous::EmbeddedDocs'] ||                 # format for embeds_many embeddings
        ['types', 'id', 'attributes'].all? { |attr| attr.in?(value.keys) } # format for embeds_one_embeddings
      )
    end

    def self.from_embedded_value(value, parent_message)
      if value['types'] == ['Promiscuous::EmbeddedDocs']
        value['attributes'].map { |attr| new(attr, parent_message) } # format for embeds_many embeddings
      else
        [ new(value, parent_message) ]                               # format for embeds_one embeddings
      end
    end

    def initialize(raw_message, embedding_message)
      @raw_message       = raw_message
      @embedding_message = embedding_message
    end

    def attributes
      super.merge(
        'embedded_in_id'    => embedding_message.id,
        'embedded_in_table' => embedding_message.table_name
      )
    end

    def operation
      'create'
    end

    private

    attr_reader :embedding_message
  end
end
