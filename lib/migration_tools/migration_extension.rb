module MigrationTools
  module MigrationExtension

    attr_accessor :migration_group

    def group(arg = nil)
      unless MigrationTools::MIGRATION_GROUPS.member?(arg.to_s)
        raise "Invalid group \"#{arg.to_s}\" - valid groups are #{MigrationTools::MIGRATION_GROUPS.inspect}"
      end

      self.migration_group = arg.to_s
    end

    def migrate(direction)
      if MigrationTools.forced? && migration_group.blank?
        raise "Cowardly refusing to run migration without a group. Read https://github.com/zendesk/migration_tools/blob/master/README.md"
      end
      super
    end
  end
end

ActiveRecord::Migration.singleton_class.send(:prepend, MigrationTools::MigrationExtension)

ActiveRecord::Migration.class_eval do
  def migration_group
    self.class.migration_group
  end
end
ActiveRecord::MigrationProxy.delegate :migration_group, :to => :migration
