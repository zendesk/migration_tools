require 'helper'

class Alpha < ActiveRecord::Migration
  group :pre
  def self.up
  end
end

class Beta < ActiveRecord::Migration
  group :pre
  def self.up
    puts "Beaver"
  end
end

class Delta < ActiveRecord::Migration
  group :change
  def self.up
  end
end

class Kappa < ActiveRecord::Migration
  def self.up
  end
end

task :environment do
  # Stub
end

MigrationTools::Tasks.new

class TestMigrationTools < Test::Unit::TestCase
  def migrations
    [ Alpha, Beta, Delta, Kappa ]
  end
  
  def proxies
    migrations.map { |m| stub(:migration => m, :version => migrations.index(m), :name => m.name) }
  end
  
  def test_grouping
    assert_equal [ Alpha, Beta ], migrations.select { |m| m.migration_group == 'pre' }
    assert_equal [ Delta ], migrations.select { |m| m.migration_group == 'change' }
    assert_equal [ Kappa ], migrations.select { |m| m.migration_group.nil? }
  end
  
  def test_runtime_checking
    begin
      eval("class Kappa < ActiveRecord::Migration; group 'drunk'; end")
      fail "You should not be able to specify custom groups"
    rescue RuntimeError => e
      assert e.message.index('Invalid group "drunk" - valid groups are ["pre", "during", "post", "change"]')
    end
  end

  def test_task_presence
    assert Rake::Task["db:migrate:list"]
    assert Rake::Task["db:migrate:group:list"]
    assert Rake::Task["db:migrate:group"]
  end

  def test_migrate_list_without_pending
    ActiveRecord::Migrator.expects(:new).returns(stub(:pending_migrations => []))
    MigrationTools::Tasks.any_instance.expects(:notify).with("Your database schema is up to date").once

    execute_task("db:migrate:list")
  end

  def test_migrate_list_with_pending
    ActiveRecord::Migrator.expects(:new).returns(stub(:pending_migrations => proxies))
    MigrationTools::Tasks.any_instance.expects(:notify).with("You have #{proxies.size} pending migrations:").once
    MigrationTools::Tasks.any_instance.expects(:notify).with("     0 Alpha").once
    MigrationTools::Tasks.any_instance.expects(:notify).with("     1 Beta").once
    MigrationTools::Tasks.any_instance.expects(:notify).with("     2 Delta").once
    MigrationTools::Tasks.any_instance.expects(:notify).with("     3 Kappa").once

    execute_task("db:migrate:list")
  end
  
  def execute_task(key)
    Rake::Task[key].invoke
    Rake::Task[key].reenable
  end
end
