require 'bundler/setup'
require 'minitest/autorun'
require 'minitest/spec'
require 'minitest/rg'
require 'mocha/minitest'
require 'active_support/all'
require 'migration_tools'

rails_version = "#{ActiveRecord::VERSION::MAJOR}.#{ActiveRecord::VERSION::MINOR}".to_f
MIGRATION_CLASS = ActiveRecord::Migration[rails_version]

dir = File.expand_path('../migrations', __FILE__)
ActiveRecord::Migrator.migrations_paths.replace([dir])
Dir.glob(File.join(dir, '*.rb')).each {|f| require f}

ActiveRecord::Migration.verbose = false
