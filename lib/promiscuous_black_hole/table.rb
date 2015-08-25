require 'promiscuous_black_hole/locker'

module Promiscuous::BlackHole
  class Table
    include TypeInferrer

    def initialize(table_name, instance_attrs)
      @table_name     = table_name.to_sym
      @instance_attrs = instance_attrs
    end

    def update_schema
      update_schema! if schema_changed?
    end

    private

    attr_reader :table_name, :instance_attrs

    def update_schema!
      Locker.new(table_name.to_s).with_lock do
        bust_cache

        create_embedding_metadata if embedded_in_table

        ensure_created
        ensure_columns
      end
    end

    def create_embedding_metadata
      attrs = {
        :parent_table => embedded_in_table,
        :child_table => table_name.to_s
      }

      embedding = DB[:embeddings].where(attrs)

      if embedding.first.nil?
        DB[:embeddings].insert(attrs)
      end
    end

    def embedded_in_table
      instance_attrs['embedded_in_table']
    end

    def schema_changed?
      !DB.table_exists?(table_name) || new_attrs.present?
    end

    def ensure_columns
      create_columns if new_attrs.present?
    end

    def new_attrs
      @new_attrs ||= instance_attrs.reject { |attr, _| existing_column_names.include?(attr) }
    end

    def existing_column_names
      @existing_column_names ||= DB[table_name].columns.map(&:to_s)
    end

    def bust_cache
      @existing_column_names = @new_attrs = nil
    end

    def create_columns
      indexed_columns = []
      column_attrs = new_attrs.map do |attr, val|
        if attr =~ /_id$/ && val.is_a?(String) && val.length == 24
          indexed_columns << attr
          [attr.to_sym, :char, { :size => 24 }]
        else
          type = type_for(val)
          if type.in?([:date, :timestamptz])
            indexed_columns << attr
          end
          [attr.to_sym, type]
        end
      end

      DB.alter_table(table_name) do
        column_attrs.each do |col_attr|
          add_column(*col_attr)
        end

        indexed_columns.each { |col| add_index col.to_sym }
      end

      Promiscuous.debug "Adding columns: ALTER TABLE #{table_name} #{column_attrs}"
    end

    def ensure_created
      DB.create_table?(table_name) do
        column :id, :char, :primary_key => true, :size => 24
        column :_v, :bigint
        column :_type, :varchar, :size => 255

        index :_type
      end

      Promiscuous.debug "Adding table: #{table_name}"
    end
  end
end
