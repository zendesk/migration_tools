require 'rake'
require 'rake/tasklib'

module MigrationTools
  class Tasks < ::Rake::TaskLib
    def initialize
      define_migrate_list
      define_migrate_group
      define_convenience_tasks
    end

    def group
      return @group if defined?(@group) && @group

      @group = ENV['GROUP'].to_s
      raise "Invalid group \"#{@group}\"" if !@group.empty? && !MIGRATION_GROUPS.member?(@group)
      @group
    end

    def group=(group)
      @group = nil
      @pending_migrations = nil
      ENV['GROUP'] = group
    end

    def migrations_paths
      ActiveRecord::Migrator.migrations_paths
    end

    def migrator(target_version = nil)
      if ActiveRecord::VERSION::MAJOR > 3
        ActiveRecord::Migrator.new(:up, ActiveRecord::Migrator.migrations(migrations_paths), target_version)
      else
        ActiveRecord::Migrator.new(:up, migrations_paths, target_version)
      end
    end

    def pending_migrations
      return @pending_migrations if defined?(@pending_migrations) && @pending_migrations
      @pending_migrations = migrator.pending_migrations
      @pending_migrations = @pending_migrations.select { |proxy| group.empty? || proxy.migration_group == group }

      @pending_migrations
    end

    def define_migrate_list
      namespace :db do
        namespace :migrate do
          desc 'Lists pending migrations'
          task :list => :environment do
            if pending_migrations.empty?
              notify "Your database schema is up to date", group
            else
              notify "You have #{pending_migrations.size} pending migrations", group
              pending_migrations.each do |migration|
                notify '  %4d %s %s' % [ migration.version, migration.migration_group.to_s[0..5].center(6), migration.name ]
              end
            end
          end
        end
      end
    end

    def define_migrate_group
      namespace :db do
        namespace :migrate do
          desc 'Runs pending migrations for a given group'
          task :group => :environment do
            if group.empty?
              notify "Please specify a migration group"
            elsif pending_migrations.empty?
              notify "Your database schema is up to date"
            else
              pending_migrations.each do |migration|
                migrator(migration.version).run
              end

              Rake::Task["db:schema:dump"].invoke if ActiveRecord::Base.schema_format == :ruby
              Rake::Task["db:structure:dump"].invoke if ActiveRecord::Base.schema_format == :sql
            end
          end
        end
      end
    end

    def define_convenience_tasks
      namespace :db do
        namespace :migrate do
          [ :list, :group ].each do |ns|
            namespace ns do
              MigrationTools::MIGRATION_GROUPS.each do |migration_group|
                desc "#{ns == :list ? 'Lists' : 'Executes' } the migrations for group #{migration_group}"
                task migration_group => :environment do
                  self.group = migration_group.to_s
                  Rake::Task["db:migrate:#{ns}"].invoke
                  Rake::Task["db:migrate:#{ns}"].reenable
                end
              end
            end
          end
        end

        namespace :abort_if_pending_migrations do
          MigrationTools::MIGRATION_GROUPS.each do |migration_group|
            desc "Raises an error if there are pending #{migration_group} migrations"
            task migration_group do
              self.group = migration_group.to_s
              Rake::Task["db:migrate:list"].invoke
              Rake::Task["db:migrate:list"].reenable
              if pending_migrations.any?
                abort "Run \"rake db:migrate\" to update your database then try again."
              end
            end
          end
        end
      end
    end

    def notify(string, group = "")
      if group.empty?
        puts string
      else
        puts string + " for group \""+group+"\""
      end
    end
  end
end
