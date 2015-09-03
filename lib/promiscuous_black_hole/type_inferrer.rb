module Promiscuous::BlackHole
  module TypeInferrer
    def self.type_for(value)
      case value
      when Array
        :"#{type_for(value.first)} array"
      when Numeric
        :float
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
  end
end
