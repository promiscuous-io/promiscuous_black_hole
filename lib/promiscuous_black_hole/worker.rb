require 'promiscuous_black_hole/message'
require 'promiscuous_black_hole/operation'
require 'promiscuous_black_hole/table'

module Promiscuous::BlackHole
  class Worker
    def initialize
      extend Promiscuous::AMQP::Subscriber
    end

    def start
      Config.connect
      ensure_embeddings_table
      subscribe(rabbit_connection_options) { |metadata, payload| process_message(metadata, payload) }
    end

    def stop
      disconnect
    end

    def process_message(metadata, payload)
      JSON.parse(payload)['operations'].each { |raw_op| process_operation(raw_op) }

      metadata.ack
    rescue Exception => orig_e
      e = Promiscuous::Error::Subscriber.new(orig_e, :payload => payload)
      Promiscuous.warn "[error] Payload: #{payload} -- Error: #{e}"
      Promiscuous::Config.error_notifier.call(e)
    end

    private

    def process_operation(raw_op)
      message = Message.new(raw_op)
      Operation.new(message).process
    end

    def ensure_embeddings_table
      DB.create_table?(:embeddings) do
        primary_key [:parent_table, :child_table], :name => :embeddings_pk
        column :parent_table, 'varchar(255)'
        column :child_table, 'varchar(255)'
      end
    end

    def rabbit_connection_options
      options = {}
      options[:queue_name] = "#{Promiscuous::Config.app}.promiscuous"
      options[:bindings] = {}

      # Subscribe to everything for subscribed exchanges
      Promiscuous::Config.subscriber_exchanges.each do |exchange|
        options[:bindings][exchange] = ['*']
      end

      # Set up sync and error exchanges
      options[:bindings][Promiscuous::Config.sync_exchange]  = [Promiscuous::Config.app, Promiscuous::Config.sync_all_routing]
      options[:bindings][Promiscuous::Config.error_exchange] = [Promiscuous::Config.retry_routing]

      options
    end
  end
end
