require 'helper'

class Alpha < ActiveRecord::Migration
  group :before
  def self.up
  end
end

class Beta < ActiveRecord::Migration
  group :before
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

class TestMigrationTools < Test::Unit::TestCase

  def setup
    ENV['GROUP'] = nil
    Rake::Task.clear
    Rake::Task.define_task(:environment)
    @task = MigrationTools::Tasks.new
  end

  def migrations
    [ Alpha, Beta, Delta, Kappa ]
  end

  def proxies
    @proxies ||= migrations.map { |m| stub(:migration => m, :version => migrations.index(m), :name => m.name, :migration_group => m.migration_group) }
  end

  def test_grouping
    assert_equal [ Alpha, Beta ], migrations.select { |m| m.migration_group == 'before' }
    assert_equal [ Delta ], migrations.select { |m| m.migration_group == 'change' }
    assert_equal [ Kappa ], migrations.select { |m| m.migration_group.nil? }
  end

  def test_runtime_checking
    begin
      eval("class Kappa < ActiveRecord::Migration; group 'drunk'; end")
      fail "You should not be able to specify custom groups"
    rescue RuntimeError => e
      assert e.message.index('Invalid group "drunk" - valid groups are ["before", "during", "after", "change"]')
    end
  end

  def test_migration_proxy_delegation
    proxy = ActiveRecord::MigrationProxy.new
    proxy.expects(:migration).returns(Delta)
    assert_equal "change", proxy.migration_group
  end

  def test_task_presence
    assert Rake::Task["db:migrate:list"]
    assert Rake::Task["db:migrate:group"]
    assert Rake::Task["db:migrate:group:before"]
    assert Rake::Task["db:migrate:group:during"]
    assert Rake::Task["db:migrate:group:after"]
    assert Rake::Task["db:migrate:group:change"]
  end

  def test_migrate_list_without_pending_without_group
    ActiveRecord::Migrator.expects(:new).returns(stub(:pending_migrations => []))
    MigrationTools::Tasks.any_instance.expects(:notify).with("Your database schema is up to date", "").once

    Rake::Task["db:migrate:list"].invoke
  end

  def test_migrate_list_without_pending_with_group
    ENV['GROUP'] = 'before'
    ActiveRecord::Migrator.expects(:new).returns(stub(:pending_migrations => []))
    MigrationTools::Tasks.any_instance.expects(:notify).with("Your database schema is up to date", "before").once

    Rake::Task["db:migrate:list"].invoke
  end

  def test_migrate_list_with_pending_without_group
    ActiveRecord::Migrator.expects(:new).returns(stub(:pending_migrations => proxies))
    MigrationTools::Tasks.any_instance.expects(:notify).with("You have #{proxies.size} pending migrations", "").once
    MigrationTools::Tasks.any_instance.expects(:notify).with("     0 before Alpha").once
    MigrationTools::Tasks.any_instance.expects(:notify).with("     1 before Beta").once
    MigrationTools::Tasks.any_instance.expects(:notify).with("     2 change Delta").once
    MigrationTools::Tasks.any_instance.expects(:notify).with("     3        Kappa").once

    Rake::Task["db:migrate:list"].invoke
  end

  def test_migrate_list_with_pending_with_group
    ENV['GROUP'] = 'before'
    ActiveRecord::Migrator.expects(:new).returns(stub(:pending_migrations => proxies))
    MigrationTools::Tasks.any_instance.expects(:notify).with("You have 2 pending migrations", "before").once
    MigrationTools::Tasks.any_instance.expects(:notify).with("     0 before Alpha").once
    MigrationTools::Tasks.any_instance.expects(:notify).with("     1 before Beta").once

    Rake::Task["db:migrate:list"].invoke
  end

  def test_migrate_group_with_group_without_pending
    ENV['GROUP'] = 'before'
    ActiveRecord::Migrator.expects(:new).returns(stub(:pending_migrations => []))
    MigrationTools::Tasks.any_instance.expects(:notify).with("Your database schema is up to date").once

    Rake::Task["db:migrate:group"].invoke
  end

  def test_migrate_group_with_pending
    ENV['GROUP'] = 'before'
    migrator = stub(:pending_migrations => proxies)
    ActiveRecord::Migrator.expects(:new).returns(migrator)
    proxies.select { |p| p.migration_group == 'before' }.each do |p|
      p.expects(:migrate).with(:up).once
      migrator.expects(:record_version_state_after_migrating).with(p.version).once
    end

    Rake::Task["db:migrate:group"].invoke
  end

  def test_migrate_with_invalid_group
    ENV['GROUP'] = 'drunk'
    begin
      Rake::Task["db:migrate:group"].invoke
      fail "Should throw an error"
    rescue RuntimeError => e
      assert e.message =~ /Invalid group/
    end
  end

  def test_convenience_list_method
    ActiveRecord::Migrator.expects(:new).returns(stub(:pending_migrations => proxies))
    MigrationTools::Tasks.any_instance.expects(:notify).with("You have 2 pending migrations", "before").once
    MigrationTools::Tasks.any_instance.expects(:notify).with("     0 before Alpha").once
    MigrationTools::Tasks.any_instance.expects(:notify).with("     1 before Beta").once

    Rake::Task["db:migrate:list:before"].invoke
  end
end
