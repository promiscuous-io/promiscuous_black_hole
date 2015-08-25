module AsyncHelper
  def eventually(time_limit=5)
    timeout ||= Time.now + time_limit.seconds
    yield
  rescue Exception => e
    sleep 0.1
    retry if Time.now < timeout
    raise e
  end
end
