module Promiscuous::BlackHole
  module DB
    def self.connection
      @@connection ||= Sequel.postgres(Config.connection_args.merge(:max_connections => 10))
    end

    def self.table_exists?(table)
      exists = connection[<<-sql]
        SELECT EXISTS (
          SELECT 1
          FROM   information_schema.tables
          WHERE  table_name = '#{table}'
          AND    table_schema = ANY (CURRENT_SCHEMAS(false))
        );
      sql
      exists.first[:exists]
    end

    def self.create_table?(table, &block)
      connection.create_table(table, &block) unless table_exists?(table)
    end

    def self.schema_exists?(schema)
      exists = connection[<<-sql]
        SELECT EXISTS (
          SELECT 1
          FROM   information_schema.schemata
          WHERE  schema_name = '#{schema}'
        );
      sql
      exists.first[:exists]
    end

    def self.ensure_embeddings_table
      DB.create_table?(:embeddings) do
        primary_key [:parent_table, :child_table], :name => :embeddings_pk
        column :parent_table, 'varchar(255)'
        column :child_table, 'varchar(255)'
      end
    end

    def self.transaction_with_applied_schema(name=nil, &block)
      if in_transaction?
        yield
      else
        name ||= Config.schema_generator.call
        unless DB.schema_exists?(name)
          DB.connection.create_schema(name) rescue nil
        end
        transaction do
          DB << "SET LOCAL search_path TO #{name}"
          ensure_embeddings_table
          yield
        end
      end
    end

    def self.[](arg)
      self.connection[arg.to_sym]
    end

    def self.method_missing(meth, *args, &block)
      self.connection.public_send(meth, *args, &block)
    end
  end
end
