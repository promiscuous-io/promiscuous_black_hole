module Promiscuous::BlackHole
  class EmbeddingsTable
    def self.dataset
      DB[:public__embeddings]
    end

    def self.ensure_exists
      return if DB.table_exists?(:embeddings, :schema => :public)
      Locker.new('embeddings').with_lock do
        DB.create_table?(:public__embeddings) do
          primary_key [:parent_table, :child_table], :name => :embeddings_pk
          column :parent_table, 'varchar(255)'
          column :child_table, 'varchar(255)'
        end
      end
    end

    def self.method_missing(*args, &block)
      dataset.public_send(*args, &block)
    end
  end
end
