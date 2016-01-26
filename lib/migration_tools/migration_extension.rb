module MigrationTools
  module MigrationExtension

    attr_accessor :migration_group

    def group(arg = nil)
      unless MigrationTools::MIGRATION_GROUPS.member?(arg.to_s)
        raise "Invalid group \"#{arg.to_s}\" - valid groups are #{MigrationTools::MIGRATION_GROUPS.inspect}"
      end

      self.migration_group = arg.to_s
    end

    def migrate_with_forced_groups(direction)
      if MigrationTools.forced? && migration_group.blank?
        raise "Cowardly refusing to run migration without a group. Read https://github.com/zendesk/migration_tools/blob/master/README.md"
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

  def migration_group
    self.class.migration_group
  end
end
ActiveRecord::MigrationProxy.delegate :migration_group, :to => :migration
