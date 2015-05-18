module Promiscuous::BlackHole
  class StaleEmbeddingsDestroyer
    def initialize(table_name, parent_id)
      @table_name = table_name
      @parent_id  = parent_id
    end

    def process
      child_tables.each do |child_table|
        child_ids_for(child_table).each do |id|
          StaleEmbeddingsDestroyer.new(child_table, id).process
        end

        criteria_for(child_table).delete
      end
    end

    def child_ids_for(table)
      criteria_for(table).map(:id)
    end

    def child_tables
      DB[:embeddings].where('parent_table = ?', @table_name).map(:child_table)
    end

    private

    def criteria_for(table)
      DB[table].where('embedded_in_id = ?', @parent_id)
    end
  end
end
