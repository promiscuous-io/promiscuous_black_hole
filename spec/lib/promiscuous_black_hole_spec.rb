require 'spec_helper'

describe Promiscuous::BlackHole do
  describe '.start' do
    it 'ensures the embeddings table' do
      allow(Promiscuous::CLI).to receive(:new).and_return(double(:cli).as_null_object)
      public_tables = -> { DB.tables(:schema => :public) }
      DB << 'DROP TABLE public.embeddings'

      expect(public_tables.()).to_not include(:embeddings)

      Promiscuous::BlackHole.start
      expect(public_tables.()).to include(:embeddings)
    end
  end
end
