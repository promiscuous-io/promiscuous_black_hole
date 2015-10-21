module LockerHelper
  mattr_accessor :block_time
  self.block_time = 0

  def self.delay_after_unlock(time, &block)
    self.block_time = time
    block.call
    self.block_time = 0
  end

end

Promiscuous::BlackHole::Locker.class_eval do
  alias_method :orig_with_lock, :with_lock

  def with_lock(&block)
    orig_with_lock(&block)
    sleep(LockerHelper.block_time)
  end
end
