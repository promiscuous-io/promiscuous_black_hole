require 'promiscuous_black_hole/eventual_destroyer'

module Promiscuous::BlackHole
  class Record
    def initialize(table_name, raw_attributes)
      @table_name = table_name
      @raw_attributes = raw_attributes
    end

    def upsert
      existing_record ? update : create
    end

    def destroy
      Promiscuous.debug "Deleting record: #{ table_name }: #{ attributes['id'] }"
      Promiscuous::Subscriber::Worker::EventualDestroyer.postpone_destroy(
        schema_name: DB.search_path,
        table_name: table_name,
        id:  attributes['id']
      )
    end

    def message_version_newer_than_persisted?
      # _v can be nil when records come in via a manual sync
      existing_record.nil? || existing_record[:_v].nil? || existing_record[:_v] <= attributes['_v'].to_i
    end

    private

    attr_reader :table_name

    def existing_record
      @existing_record ||= criteria.first
    end

    def update
      Promiscuous.debug "Updating record: [ #{attributes} ]"
      criteria.update(attributes)
    end

    def create
      Promiscuous.debug "Creating record: #{attributes.values}"
      DB[table_name].insert(attributes)
    end

    def attributes
      return @attributes if @attributes

      @attributes = @raw_attributes.dup
      @attributes.each do |k, v|
        if v.is_a?(Hash)
          @attributes[k] = MultiJson.dump(v)
        end
      end
    end

    def criteria
      DB[table_name].where('id = ?', attributes['id'])
    end
  end
end
