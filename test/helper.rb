require 'test/unit'
require 'mocha'

$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require 'migration_tools'

ActiveRecord::Base.establish_connection(
  :adapter => "sqlite3",
  :database => ":memory:"
)

