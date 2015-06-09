require 'bundler/setup'

require 'active_support'
require 'promiscuous'
require 'sequel'

require 'promiscuous_black_hole/config'
require 'promiscuous_black_hole/db'
require 'promiscuous_black_hole/worker'
require 'promiscuous_black_hole/unit_of_work'

module Promiscuous::BlackHole
  def self.start
    connect
    ensure_embeddings_table
    cli = Promiscuous::CLI.new
    cli.options[:action] = :subscribe
    cli.run
  end

  def self.subscribing_to?(collection)
    Config.subscriptions == :__all__ ||
      collection.to_sym.in?(Config.subscriptions)
  end

  def self.connect
    Promiscuous.ensure_connected
    Config.connect
  end

  def self.ensure_embeddings_table
    DB.create_table?(:embeddings) do
      primary_key [:parent_table, :child_table], :name => :embeddings_pk
      column :parent_table, 'varchar(255)'
      column :child_table, 'varchar(255)'
    end
  end
end
