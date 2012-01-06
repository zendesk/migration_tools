require 'active_record'
require 'active_record/migration'

require 'migration_tools/migration_extension'
require 'migration_tools/tasks'

module MigrationTools
  DEFAULT_MIGRATION_GROUPS = [ 'before', 'during', 'after', 'change' ]

  def self.forced?
    !!@forced
  end

  def self.forced!
    @forced = true
  end

  def self.migration_groups
    @groups ||= DEFAULT_MIGRATION_GROUPS.clone
  end
end
