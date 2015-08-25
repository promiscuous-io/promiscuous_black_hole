module Promiscuous::BlackHole
  module Config
    cattr_accessor :subscriptions, :connection_args, :schema_generator

    def self.subscriptions=(val)
      @@subscriptions = val.is_a?(Array) ? val.map(&:to_sym) : val.to_sym
    end

    def self.configure(&block)
      block.call(self)
    end
  end
end
