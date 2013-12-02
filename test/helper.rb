require 'bundler/setup'
require 'minitest/autorun'
require 'minitest/spec'
require 'minitest/rg'
require 'mocha/setup'
require 'active_support/all'

$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require 'migration_tools'

ActiveRecord::Base.establish_connection(
  :adapter => "sqlite3",
  :database => ":memory:"
)
