module Promiscuous::BlackHole
  module DB
    def self.connection
      @@connection ||= Sequel.postgres(Config.connection_args.merge(:max_connections => 10))
    end

    def self.table_exists?(table, opts = {})
      DB.tables(opts).include?(table.to_sym)
    end

    def self.create_table?(table, &block)
      connection.create_table(table, &block) unless table_exists?(table)
    end

    def self.search_path
      fetch('show search_path').first[:search_path]
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
