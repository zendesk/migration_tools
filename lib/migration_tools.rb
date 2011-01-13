require 'active_record'
require 'active_record/migration'

require 'migration_tools/migration_extension'
require 'migration_tools/tasks'

module MigrationTools
  def self.forced?
    !!@forced
  end

  def self.forced!
    @forced = true
  end

  MIGRATION_GROUPS = [ 'before', 'during', 'after', 'change' ]
end
