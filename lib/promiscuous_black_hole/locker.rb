require 'robust-redis-lock'

module Promiscuous::BlackHole
  class Locker
    LOCK_OPTIONS = { :timeout => 1.5.minute, # after 1.5 minute, we give up
                     :sleep   => 0.01,       # polling every 10ms.
                     :expire  => 1.minute }  # after one minute, we are considered dead

    def initialize(key)
      @key = key
    end

    def with_lock(&block)
      begin
        lock.lock
        block.call
      ensure
        lock.try_unlock
      end
    rescue Redis::Lock::Recovered
      retry
    end

    private

    def lock
      @lock ||= Redis::Lock.new(@key, LOCK_OPTIONS.merge(:redis => Promiscuous::Redis.connection))
    end
  end
end
