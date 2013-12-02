require File.expand_path '../helper', __FILE__

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
    Rake::Task.define_task("environment")
    Rake::Task.define_task("db:schema:dump")
    @task = MigrationTools::Tasks.new

    def @task.abort(msg = nil)
      @aborted = true
    end

    def @task.aborted?
      @aborted || false
    end
  end

  def migrations
    [ Alpha, Beta, Delta, Kappa ]
  end

  def old_migrator?
    ActiveRecord::VERSION::MAJOR == 2 || (ActiveRecord::VERSION::MAJOR == 3 && ActiveRecord::VERSION::MINOR == 0)
  end

  def proxies
    @proxies ||= migrations.map { |m| migration_proxy(m) }
  end

  def migration_proxy(m)
    name = m.name
    version = migrations.index(m)

    if old_migrator?
      proxy = ActiveRecord::MigrationProxy.new
      proxy.name = name
      proxy.version = version
    else
      proxy = ActiveRecord::MigrationProxy.new(name, version, nil, nil)
    end
    proxy.instance_variable_set(:@migration, (old_migrator? ? m : m.new))
    proxy
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
    args = if ActiveRecord::VERSION::MAJOR == 3 && ActiveRecord::VERSION::MINOR > 0
      [:name, :version, :filename, :scope]
    else
      []
    end

    proxy = ActiveRecord::MigrationProxy.new(*args)
    proxy.expects(:migration).returns(Delta)
    assert_equal "change", proxy.migration_group
  end

  def test_forcing
    assert !MigrationTools.forced?
    Kappa.migrate("up")

    MigrationTools.forced!
    assert MigrationTools.forced?

    Alpha.migrate("up")
    begin
      Kappa.migrate("up")
      fail "You should not be able to run migrations without groups in forced mode"
    rescue RuntimeError => e
      assert e.message =~ /Cowardly refusing/
    end
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

  def test_abort_if_pending_migrations_with_group_without_migrations
    @task.stubs(:notify)
    ActiveRecord::Migrator.expects(:new).returns(stub(:pending_migrations => proxies))
    Rake::Task["db:abort_if_pending_migrations:after"].invoke
    assert !@task.aborted?, "aborted where it shouldn't"
  end

  def test_abort_if_pending_migrations_with_group_with_migrations
    @task.stubs(:notify)
    ActiveRecord::Migrator.expects(:new).returns(stub(:pending_migrations => proxies))
    Rake::Task["db:abort_if_pending_migrations:before"].invoke
    assert @task.aborted?, "did not abort"
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
      ActiveRecord::Migrator.expects(:run).with(:up, 'db/migrate', p.version).once
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
