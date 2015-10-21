require 'promiscuous_black_hole/locker'
require 'promiscuous_black_hole/record'
require 'promiscuous_black_hole/stale_embeddings_destroyer'
require 'promiscuous_black_hole/table'

module Promiscuous::BlackHole
  class Operation
    def initialize(message, embedded: false)
      @message = message
      @embedded = embedded
    end

    def self.process(message)
      new(message).process
    end

    def process
      return unless Promiscuous::BlackHole.subscribing_to?(message.base_type)
      with_wrapped_error do
        process!
      end
    end

    def update_schema
      table.update_schema
      embedded_operations.each(&:update_schema)
    end

    def persist
      Promiscuous.debug "Processing op: #{ message }"

      case message.operation
      when 'create', 'update' then upsert
      when 'destroy' then destroy
      end
    end

    def schema_changed?
      table.schema_changed? || embedded_operations.any?(&:schema_changed?)
    end

    private

    attr_reader :message

    def in_transaction(&block)
      DB.transaction_with_applied_schema(schema, &block)
    end

    def schema
      @schema ||= Config.schema_generator.call
    end

    def process!
      if in_transaction { schema_changed? }
        Locker.new(message.table_name.to_s).with_lock { in_transaction { update_schema } }
      end

      Locker.new(message.id).with_lock { in_transaction { persist } }
    end

    def upsert
      if record.message_version_newer_than_persisted?
        record.upsert
        persist_embedded_records
      end
    end

    def destroy
      record.destroy
      persist_embedded_records
    end

    def persist_embedded_records
      StaleEmbeddingsDestroyer.new(message.table_name, message.id).process unless @embedded
      embedded_operations.each(&:persist)
    end

    def record
      Record.new(message.table_name, message.attributes)
    end

    def table
      Table.new(message.table_name, message.attributes)
    end

    def embedded_operations
      @embedded_operations ||= message.embedded_messages.map { |em| Operation.new(em, embedded: true)}
    end

    def with_wrapped_error(&block)
      block.call
    rescue => orig_e
      e = Promiscuous::Error::Subscriber.new(orig_e, :payload => message.raw_message)
      Promiscuous.warn "[receive] #{message.raw_message} #{e}\n#{e.backtrace.join("\n")}"
      raise e
    end
  end
end
