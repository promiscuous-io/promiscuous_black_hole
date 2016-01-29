module Promiscuous::BlackHole
  module Config
    cattr_accessor :subscriptions, :connection_args, :schema_generator, :delete_mode

    self.delete_mode = :hard

    def self.subscriptions=(val)
      @@subscriptions = val.is_a?(Array) ? val.map(&:to_sym) : val.to_sym
    end

    def self.delete_mode=(val)
      unless [:soft, :hard].include?(val)
        raise "Invalid option for 'delete_mode' given: #{val}, must be one of :soft or :hard"
      end
      @@delete_mode = val
    end

    def self.configure(&block)
      block.call(self)
    end

    def self.hard_deletes?
      self.delete_mode == :hard
    end
  end
end
