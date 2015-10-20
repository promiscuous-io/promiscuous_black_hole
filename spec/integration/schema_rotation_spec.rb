require 'spec_helper'

describe Promiscuous::BlackHole do
  it 'sets the search path correctly on processing each message' do
    Promiscuous::BlackHole::Config.configure do |cfg|
      cfg.schema_generator = -> { @expected_schema_name }
    end

    [Time.now, Time.now + 1.hour].each do |time|
      @expected_schema_name = time.beginning_of_hour.to_i.to_s
      PublisherModel.create!

      eventually do
        DB.transaction_with_applied_schema(@expected_schema_name) do
          expect(DB[:publisher_models].count).to eq 1
        end
      end
    end
  end

  describe 'handling embeddings' do
    before do
      $schema_name = 'public'
      Promiscuous::BlackHole::Config.configure do |cfg|
        cfg.schema_generator = -> { $schema_name}
      end
    end

    after { $schema_name = nil }

    it 'reads and writes the embeddings table from the public schema' do
      $schema_name = 'anything'

      PublisherModel.create!

      eventually do
        expect(DB.tables).to include(:embeddings)
        expect(DB.tables(:schema => 'anything')).not_to include(:embeddings)
      end
    end

    it 'ignores embeddings that do not exist for the current schema' do
      $schema_name = 'anything'

      class PublisherModel
        embeds_one :embedded_publishers
        publish :embedded_publishers
      end

      define_constant :EmbeddedPublisher do
        include Mongoid::Document
        include Promiscuous::Publisher
        embedded_in :publisher_model
      end

      PublisherModel.create!(:embedded_publishers => EmbeddedPublisher.new)

      sleep 0.1
      $schema_name = 'new_schema'
      PublisherModel.create!

      eventually do
        expect(DB[:new_schema__publisher_models].count).to eq(1)
      end
    end
  end

  it 'deletes from the right schema' do
    Promiscuous::BlackHole::Config.configure do |cfg|
      cfg.schema_generator = -> { @expected_schema_name }
    end

    Promiscuous::Config.destroy_timeout = 1.second

    @expected_schema_name = 'foo'
    m = PublisherModel.create!(:group => 3)
    m.destroy
    sleep 0.3
    @expected_schema_name = 'bar'

    eventually do
      expect(DB[:foo__publisher_models].count).to eq(0)
    end
  end

  it 'gracefully switches between schemata' do
    test_size = 10
    max_writes_per_schema = 5

    Promiscuous::BlackHole::Config.configure do |cfg|
      schema = 0
      writes_to_schema = 0
      mutex = Mutex.new

      cfg.schema_generator = -> do
        mutex.synchronize do
          if writes_to_schema == max_writes_per_schema
            writes_to_schema = 0
            schema += 1
          end
          writes_to_schema += 1
        end

        schema
      end
    end

    (test_size * max_writes_per_schema).times do |i|
      field_name = "field_#{i/max_writes_per_schema}"

      PublisherModel.instance_eval do
        if i % max_writes_per_schema == 0
          field field_name
          publish field_name
        end
        create(field_name => 'data')
      end
    end

    eventually do
      total_writes = user_written_schemata.inject(0) do |writes, schema|
        DB.transaction_with_applied_schema(schema) do
          writes += DB[:publisher_models].count
        end
        writes
      end

      expect(total_writes).to eq(test_size * max_writes_per_schema)
    end
  end
end
