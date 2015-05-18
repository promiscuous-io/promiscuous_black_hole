class Promiscuous::Subscriber::UnitOfWork
  def operations
    message.parsed_payload['operations'].map do |op|
      Promiscuous::BlackHole::Message.new(op)
    end
  end

  def on_message
    operations.each { |op| Promiscuous::BlackHole::Operation.process(op) }
    message.ack
  end
end
