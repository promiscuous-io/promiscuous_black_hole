shared_examples_for 'adding a column' do
  before do
    PublisherModel.create!(:group => input_value)
  end

  it "has appropriate type" do
    eventually do
      column = schema_hash_for(:publisher_models)[:group]
      expect(column).to include(:db_type => expected_db_type)
    end
  end

  it "adds the index if it should" do
    eventually do
      index_attrs = {:columns => [:group], :unique => false, :deferrable=>nil}
      indexes = DB.indexes(:publisher_models).values

      if indexed
        expect(indexes).to include(index_attrs)
      else
        expect(indexes).to_not include(index_attrs)
      end
    end
  end
end
