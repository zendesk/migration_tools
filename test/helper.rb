require 'bundler/setup'
require 'minitest/autorun'
require 'minitest/spec'
require 'minitest/rg'
require 'mocha/setup'
require 'active_support/all'
require 'migration_tools'

MIGRATION_CLASS = if ActiveRecord::Migration.respond_to?(:[])
  rails_version = "#{ActiveRecord::VERSION::MAJOR}.#{ActiveRecord::VERSION::MINOR}".to_f
  ActiveRecord::Migration[rails_version]
else
  ActiveRecord::Migration
end

dir = File.expand_path('../migrations', __FILE__)
ActiveRecord::Migrator.migrations_paths.replace([dir])
Dir.glob(File.join(dir, '*.rb')).each {|f| require f}

ActiveRecord::Migration.verbose = false
