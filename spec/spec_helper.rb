require 'bundler/setup'
require 'database_cleaner'
require 'event_bus'
require 'active_record'
require 'active_model'

ENV['RACK_ENV'] = 'test'
RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before(:context, :db) do
    ActiveRecord::Base.establish_connection :adapter => 'sqlite3', database: ':memory:'
    ActiveRecord::Base.connection.execute "CREATE table test (id INTEGER NOT NULL PRIMARY KEY)"
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:suite) do
    puts "Started at: #{Time.now}"
    DatabaseCleaner.strategy = :transaction
  end

  config.before(:each, :db) do
    DatabaseCleaner.start
  end

  config.after(:each, :db) do
    DatabaseCleaner.clean
  end
end
