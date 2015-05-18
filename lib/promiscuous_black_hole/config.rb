module Promiscuous::BlackHole
  module Config
    cattr_accessor :subscriptions, :connection_args

    def self.subscriptions=(val)
      @@subscriptions = val.is_a?(Array) ? val.map(&:to_sym) : val.to_sym
    end

    def self.configure(&block)
      block.call(self)
    end

    def self.connect
      DB.connect(connection_args)
    end
  end
end
