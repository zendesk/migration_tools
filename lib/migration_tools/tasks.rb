require 'rake'
require 'rake/tasklib'

module MigrationTools
  class Tasks < ::Rake::TaskLib
    attr_accessor :group

    def initialize
      self.group = ENV['GROUP'] || ''
      define
    end

    def define
      define_migrate_list
      define_migrate_group
      define_migrate_group_list
    end

    def define_migrate_list
      namespace :db do
        namespace :migrate do
          desc 'Lists the migrations that are pending and will get run once db:migrate is executed'
          task :list => :environment do
            pending_migrations = ActiveRecord::Migrator.new(:up, 'db/migrate').pending_migrations

            if pending_migrations.any?
              notify "You have #{pending_migrations.size} pending migrations:"
              pending_migrations.each do |pending_migration|
                notify '  %4d %s' % [ pending_migration.version, pending_migration.name ]
              end
            else
              notify "Your database schema is up to date"
            end
          end
        end
      end
    end

    def define_migrate_group_list
      namespace :db do
        namespace :migrate do
          namespace :group do
            desc 'Lists pending migrations for the specified group, e.g. $ GROUP=pre rake db:migrate:group:list'
            task :list => :environment do
              if !group.empty? && !MIGRATION_GROUPS.member?(group)
                notify "Invalid migration group: #{group}"
                return
              end

              pending_migrations = ActiveRecord::Migrator.new(:up, 'db/migrate').pending_migrations.map { |proxy| proxy.send(:migration) }
              group_migrations   = pending_migrations.map { |migration| group.empty? || migration.migration_group == group }.sort { |x, y| x.migration_group.to_s <=> y.migration_group.to_s }

              if group_migrations.any?
                if !group.empty?
                  notify "You have #{group_migrations.size} pending migrations in group #{group}:"
                  group_migrations.each do |group_migration|
                    notify '  %4d %s' % [ group_migration.version, group_migration.name ]
                  end
                else
                  notify "You have #{group_migrations.size} pending migrations (by group):"
                  group_migrations.each do |group_migration|
                    notify '  %4d %s %s' % [ group_migration.version, group_migration.migration_group.to_s[0..2].center(3), group_migration.name ]
                  end
                end
              else
                notify "No pending migrations in group #{group}"
              end
            end
          end
        end
      end
    end

    def define_migrate_group
      namespace :db do
        namespace :migrate do
          desc 'Executes the given group of migrations, e.g. $ GROUP=pre rake db:migrate:group'
          task :group => :environment do
            if !MIGRATION_GROUPS.member?(group)
              notify "Invalid migration group \"#{group}\" - aborting"
              return
            end

            pending_migrations = ActiveRecord::Migrator.new(:up, 'db/migrate').pending_migrations
            group_migrations   = pending_migrations.map { |proxy| migration.send(:migration).migration_group == group }

            if group_migrations.any?
              group_migrations.each do |migration|
                migration.migrate
              end
            else
              notify "No pending migrations in group #{group}"
            end
          end
        end
      end
    end
    
    def notify(string)
      puts string
    end
  end
end
