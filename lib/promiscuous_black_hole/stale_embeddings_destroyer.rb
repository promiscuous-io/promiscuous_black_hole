module Promiscuous::BlackHole
  class StaleEmbeddingsDestroyer
    def initialize(table_name, parent_id, cached_embeddings={})
      @table_name = table_name
      @parent_id  = parent_id
      @cached_embeddings = cached_embeddings
    end

    def process
      child_tables.each do |child_table|
        child_ids_for(child_table).each do |id|
          StaleEmbeddingsDestroyer.new(child_table, id, @cached_embeddings).process
        end

        criteria_for(child_table).delete
      end
    end

    def child_ids_for(table)
      criteria_for(table).map(:id)
    end

    def child_tables
      criteria = DB[:embeddings].where('parent_table = ?', @table_name)
      @cached_embeddings[criteria.sql.hash] ||= criteria.map(:child_table)
    end

    private

    def criteria_for(table)
      DB[table].where('embedded_in_id = ?', @parent_id)
    end
  end
end
