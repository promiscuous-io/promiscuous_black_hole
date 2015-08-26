require 'bson'

module Promiscuous::BlackHole
  class EmbeddedMessage < Message
    def self.embedded_value?(value)
      PARSERS.any? { |parser| parser.matching_embedding?(value) }
    end

    def self.from_embedded_value(key, value, parent_message)
      PARSERS.detect { |parser| parser.matching_embedding?(value) }.from_value(key, value, parent_message)
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

    module EmbedsManyParser
      def self.matching_embedding?(value)
        value.kind_of?(Hash) && value['types'] == ['Promiscuous::EmbeddedDocs']
      end

      def self.from_value(_, value, parent_message)
        value['attributes'].map { |attr| EmbeddedMessage.new(attr, parent_message) }
      end
    end

    module EmbedsOneParser
      def self.matching_embedding?(value)
        value.kind_of?(Hash) && ['types', 'id', 'attributes'].all? { |attr| attr.in?(value.keys) }
      end

      def self.from_value(_, value, parent_message)
        [ EmbeddedMessage.new(value, parent_message) ]
      end
    end

    module ArrayFieldParser
      def self.matching_embedding?(value)
        value.kind_of?(Array)
      end

      def self.from_value(key, value, parent_message)
        message_payload = { 'types' =>["#{parent_message.table_name.singularize}$#{ key }"] }
        value.map do |element|
          custom_attrs = { 'attributes' => { key.singularize => element }, 'id' => BSON::ObjectId.new.to_s }
          EmbeddedMessage.new(message_payload.merge(custom_attrs), parent_message)
        end
      end
    end

    PARSERS = [ EmbedsManyParser, EmbedsOneParser, ArrayFieldParser ]
  end
end
