require 'set'

class EmbeddingSet
  def initialize
    @data = Set.new
    @loaded = false
  end

  def [](parent_table)
    ensure_loaded
    @data[parent_table]
  end

  def include?(embedding)
    ensure_loaded
    self[embedding[:parent_table]].include?(embedding[:child_table])
  end

  def add(embedding)
    ensure_loaded
    if include?(embedding)
      false
    else
      DB[:embeddings].insert(attrs)
      add_to_data(embedding)
      true
    end
  end

  private

  def add_to_data(embedding)
    parent = embedding[:parent_table]
    @data[parent] ||= Set.new
    @data[parent].add(embedding[:child_table])
  end

  def ensure_embeddings_table
    DB.create_table?(:embeddings) do
      primary_key [:parent_table, :child_table], :name => :embeddings_pk
      column :parent_table, 'varchar(255)'
      column :child_table, 'varchar(255)'
    end
  end

  def load
    ensure_embeddings_table

    DB[:embeddings].each do |embedding|
      add_to_data(embedding)
    end

    @loaded = true
  end

  def ensure_loaded
    load unless @loaded
  end
end
