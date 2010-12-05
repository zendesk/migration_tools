require 'active_record'
require 'active_record/migration'

require 'migration_tools/migration_extension'
require 'migration_tools/tasks'

module MigrationTools
  MIGRATION_GROUPS = [ 'before', 'during', 'after', 'change' ]
end
