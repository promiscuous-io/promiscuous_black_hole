require 'promiscuous_black_hole/locker'
require 'promiscuous_black_hole/record'
require 'promiscuous_black_hole/stale_embeddings_destroyer'
require 'promiscuous_black_hole/table'

module Promiscuous::BlackHole
  class Operation
    def initialize(message)
      @message = message
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

    private

    attr_reader :message

    def process!
      Locker.new(message.id).with_lock do
        DB.transaction_with_applied_schema do
          update_schema
          persist
        end
      end
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
      StaleEmbeddingsDestroyer.new(message.table_name, message.id).process
      embedded_operations.each(&:persist)
    end

    def record
      Record.new(message.table_name, message.attributes)
    end

    def table
      Table.new(message.table_name, message.attributes)
    end

    def embedded_operations
      @embedded_operations ||= message.embedded_messages.map { |em| Operation.new(em) }
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
