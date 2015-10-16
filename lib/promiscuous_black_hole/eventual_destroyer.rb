class Promiscuous::Subscriber::Worker::EventualDestroyer
  def self.postpone_destroy(schema_name:, table_name:, id:)
    PendingDestroy.create(
      :class_name => table_name.to_s,
      :schema_name => schema_name.to_s,
      :instance_id => id
    )
  end

  class PendingDestroy
    def perform
      Promiscuous::BlackHole::DB[qualified_table_name].where('id = ?', instance_id).delete
    end

    private

    def qualified_table_name
      :"#{schema_name}__#{class_name}"
    end

    def schema_name
      @schema_name ||= MultiJson.load(@raw)['schema_name']
    end
  end
end
