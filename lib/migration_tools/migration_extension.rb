module MigrationTools
  module MigrationExtension
    module ClassMethods
      attr_accessor :migration_group

      def group(arg = nil)
        unless MigrationTools::MIGRATION_GROUPS.member?(arg.to_s)
          raise "Invalid group \"#{arg.to_s}\" - valid groups are #{MigrationTools::MIGRATION_GROUPS.inspect}"
        end

        self.migration_group = arg.to_s
      end
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
  extend MigrationTools::MigrationExtension::ClassMethods
  include MigrationTools::MigrationExtension

  alias_method :migrate_without_forced_groups, :migrate
  alias_method :migrate, :migrate_with_forced_groups

  def migration_group
    self.class.migration_group
  end
end

ActiveRecord::MigrationProxy.delegate :migration_group, :to => :migration
