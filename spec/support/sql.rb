module SqlHelper
  def schema_hash_for(table)
    Hash[DB.schema(table)]
  end

  def extract_array(parent, field)
    DB[:"#{parent}$#{field.pluralize}"].map { |row| row[field.to_sym] }
  end

  def user_written_schemata
    DB[:"information_schema__schemata"]
      .map { | schema| schema[:schema_name] }
      .reject { |schema| schema =~ /^pg_/ || schema.in?(['information_schema', 'public']) }
  end
end
