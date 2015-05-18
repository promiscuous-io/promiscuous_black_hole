module SqlHelper
  def schema_hash_for(table)
    Hash[DB.schema(table)]
  end
end
