module Promiscuous::BlackHole
  module TypeInferrer
    def type_for(value)
      case value
      when Array
        :"#{type_for(value.first)} array"
      when Numeric
        :float
      when Hash
        :json
      when /^\d{4}-\d{2}-\d{2}.\d{2}:\d{2}:\d{2}/
        :timestamptz
      when /^\d{4}-\d{2}-\d{2}$/
        :date
      when true, false
        :boolean
      else
        :text
      end
    end

    def sql_representation_for(value)
      case value
      when Hash
        Sequel.pg_json(value)
      else
        value
      end
    end
  end
end
