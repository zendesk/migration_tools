module MigrationTools
  module MigrationExtension

    attr_accessor :migration_group

    def group(arg = nil)
      unless MigrationTools.migration_groups.member?(arg.to_s)
        raise "Invalid group \"#{arg.to_s}\" - valid groups are #{MigrationTools.migration_groups.inspect}"
      end

      self.migration_group = arg.to_s
    end

    def migrate_with_forced_groups(direction)
      if MigrationTools.forced? && migration_group.blank?
        raise "Cowardly refusing to run migration without a group. Read https://github.com/morten/migration_tools/blob/master/README.rdoc"
      end
      migrate_without_forced_groups(direction)
    end
  end
end

ActiveRecord::Migration.class_eval do
  extend MigrationTools::MigrationExtension
  class << self
    alias_method_chain :migrate, :forced_groups
  end
end
ActiveRecord::MigrationProxy.delegate :migration_group, :to => :migration
