require 'bundler'
require 'mongoid'
require 'pry'
require 'rspec'

require 'promiscuous_black_hole'

DATABASE = 'promiscuous_black_hole_test'

PROMISCUOUS_SPEC_SUPPORT_PATH = Gem::Specification.find_all_by_name('promiscuous').first.gem_dir + '/../spec/support/'

DB = Promiscuous::BlackHole::DB

['test_cluster', 'amqp', 'kafka', 'backend', 'macros/define_constant'].each do |helper|
  require PROMISCUOUS_SPEC_SUPPORT_PATH + helper
end

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

Promiscuous::BlackHole::Config.configure do |config|
  config.connection_args = { database: DATABASE }
  config.subscriptions   = :__all__
end

RSpec.configure do |config|
  config.color = true

  config.include AsyncHelper
  config.include AMQPHelper
  config.include KafkaHelper
  config.include BackendHelper
  config.include ModelsHelper
  config.include SqlHelper

  config.after { Promiscuous::Loader.cleanup }
end

RSpec.configure do |config|
  config.before(:each) do
    Mongoid.purge!
    use_real_backend {}
    load_models
    Promiscuous::BlackHole.connect

    run_subscriber_worker!
    DB.drop_table(*DB.tables)
    Promiscuous::BlackHole.ensure_embeddings_table
  end

  config.after(:each) do
    DB.disconnect
  end
end
