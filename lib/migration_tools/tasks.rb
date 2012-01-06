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
      return @group if @group

      @group = ENV['GROUP'].to_s
      raise "Invalid group \"#{@group}\"" if !@group.empty? && !MigrationTools.migration_groups.member?(@group)
      @group
    end

    def migrator
      @migrator ||= ActiveRecord::Migrator.new(:up, 'db/migrate')
    end

    def pending_migrations
      return @pending_migrations if @pending_migrations
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
                ActiveRecord::Migrator.run(:up, 'db/migrate', migration.version)
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
              MigrationTools.migration_groups.each do |migration_group|
                desc "#{ns == :list ? 'Lists' : 'Executes' } the migrations for group #{migration_group}"
                task migration_group => :environment do
                  ENV['GROUP'] = migration_group.to_s
                  Rake::Task["db:migrate:#{ns}"].invoke
                end
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
