class Promiscuous::Subscriber::Worker::EventualDestroyer
  class PendingDestroy
    def perform
      Promiscuous::BlackHole::DB[class_name].where('id = ?', instance_id).delete
    end
  end
end
