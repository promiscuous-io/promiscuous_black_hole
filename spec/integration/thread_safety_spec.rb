require 'spec_helper'

describe 'handling many concurrent schema changes' do
  it 'does not fail first when many jobs are writing concurrently' do
    @error = false
    use_real_backend { |config| config.error_notifier = proc { @error = true } }

    LockerHelper.delay_after_unlock(0.5) do
      5.times { PublisherModel.create(:group => 1) }
      sleep 1
    end

    expect(@error).to eq(false)
  end
end
