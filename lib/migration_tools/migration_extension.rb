module MigrationTools
  module MigrationExtension
    attr_accessor :migration_group
    def group(arg = nil)
      unless MigrationTools::MIGRATION_GROUPS.member?(arg.to_s)
        raise "Invalid group \"#{arg.to_s}\" - valid groups are #{MigrationTools::MIGRATION_GROUPS.inspect}"
      end

      self.migration_group = arg.to_s
    end
  end
end

ActiveRecord::Migration.class_eval { extend MigrationTools::MigrationExtension }
ActiveRecord::MigrationProxy.delegate :migration_group, :to => :migration
