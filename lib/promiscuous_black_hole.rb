require 'bundler/setup'

require 'active_support'
require 'promiscuous'
require 'sequel'

require 'promiscuous_black_hole/config'
require 'promiscuous_black_hole/db'
require 'promiscuous_black_hole/unit_of_work'

module Promiscuous::BlackHole
  def self.start
    connect
    cli = Promiscuous::CLI.new
    cli.options = { :action => :subscribe }
    cli.run
  end

  def self.subscribing_to?(collection)
    Config.subscriptions == :__all__ ||
      collection.to_sym.in?(Config.subscriptions)
  end

  def self.configure(&block)
    Config.configure(&block)
  end

  def self.connect
    Promiscuous.ensure_connected
  end
end
