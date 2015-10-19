require 'bundler'
require 'mongoid'
require 'pry'
require 'rspec'

require 'promiscuous_black_hole'

DATABASE = 'promiscuous_black_hole_test'

DB = Promiscuous::BlackHole::DB

Dir["./spec/support/**/*.rb"].each {|f| require f}

Mongoid.configure do |config|
  uri = ENV['BOXEN_MONGODB_URL']
  uri ||= "mongodb://localhost:27017/"
  uri += DATABASE

  config.sessions = { :default => { :uri => uri } }

  if ENV['LOGGER_LEVEL']
    Moped.logger = Logger.new(STDOUT).tap { |l| l.level = ENV['LOGGER_LEVEL'].to_i }
  end
end

def reload_configuration
  use_real_backend { |c| c.subscriber_threads = 2 }

  Promiscuous::BlackHole::Config.configure do |config|
    config.connection_args = { database: DATABASE }
    config.subscriptions   = :__all__
    config.schema_generator = -> { "public" }
  end
end

def clear_data
  Mongoid.purge!

  user_written_schemata.each do |schema|
    DB.run("DROP SCHEMA \"#{schema}\" CASCADE")
  end
  DB.drop_table(*DB.tables)
  Promiscuous::BlackHole::EmbeddingsTable.ensure_exists
end

RSpec.configure do |config|
  config.color = true

  config.include AsyncHelper
  config.include KafkaHelper
  config.include BackendHelper
  config.include ModelsHelper
  config.include SqlHelper

  config.after { Promiscuous::Loader.cleanup }
end

RSpec.configure do |config|
  config.before(:each) do
    load_models
    reload_configuration
    clear_data

    run_subscriber_worker!
  end

  config.after(:each) do
    DB.disconnect
  end
end
