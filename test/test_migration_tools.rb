require File.expand_path '../helper', __FILE__

describe MigrationTools do
  before do
    ENV['GROUP'] = nil

    ActiveRecord::Base.establish_connection(
      :adapter => "sqlite3",
      :database => ":memory:"
    )

    Rake::Task.clear
    Rake::Task.define_task("environment")
    Rake::Task.define_task("db:schema:dump")

    @task = MigrationTools::Tasks.new
  end

  after do
    MigrationTools.instance_variable_set('@forced', false)
  end

  def migrations
    [ Alpha, Beta, Delta, Kappa ]
  end

  def proxies
    @proxies ||= migrations.map { |m| migration_proxy(m) }
  end

  def migration_proxy(m)
    name = m.name
    version = migrations.index(m)

    proxy = ActiveRecord::MigrationProxy.new(name, version, nil, nil)
    proxy.instance_variable_set(:@migration, m.new)
    proxy
  end

  it "grouping" do
    assert_equal [ Alpha, Beta ], migrations.select { |m| m.migration_group == 'before' }
    assert_equal [ Delta ], migrations.select { |m| m.migration_group == 'change' }
    assert_equal [ Kappa ], migrations.select { |m| m.migration_group.nil? }
  end

  it "runtime_checking" do
    begin
      eval("class Kappa < MIGRATION_CLASS; group 'drunk'; end")
      fail "You should not be able to specify custom groups"
    rescue RuntimeError => e
      assert e.message.index('Invalid group "drunk" - valid groups are ["before", "during", "after", "change"]')
    end
  end

  it "migration_proxy_delegation" do
    proxy = ActiveRecord::MigrationProxy.new(:name, :version, :filename, :scope)
    proxy.expects(:migration).returns(Delta)
    assert_equal "change", proxy.migration_group
  end

  it "forcing" do
    assert !MigrationTools.forced?
    MigrationTools.forced!
    assert MigrationTools.forced?

    @task.migrator(0).run

    begin
      @task.migrator(3).run
      fail "You should not be able to run migrations without groups in forced mode"
    rescue => e
      assert e.message =~ /Cowardly refusing/
    end
  end

  it "task_presence" do
    assert Rake::Task["db:migrate:list"]
    assert Rake::Task["db:migrate:group"]
    assert Rake::Task["db:migrate:group:before"]
    assert Rake::Task["db:migrate:group:during"]
    assert Rake::Task["db:migrate:group:after"]
    assert Rake::Task["db:migrate:group:change"]
  end

  it "migrate_list_without_pending_without_group" do
    0.upto(3).each {|i| @task.migrator(i).run}

    MigrationTools::Tasks.any_instance.expects(:notify).with("Your database schema is up to date", "").once

    Rake::Task["db:migrate:list"].invoke
  end

  it "migrate_list_without_pending_with_group" do
    @task.migrator(0).run
    @task.migrator(1).run

    MigrationTools::Tasks.any_instance.expects(:notify).with("Your database schema is up to date", "before").once

    ENV['GROUP'] = 'before'
    Rake::Task["db:migrate:list"].invoke
  end

  it "migrate_list_with_pending_without_group" do
    MigrationTools::Tasks.any_instance.expects(:notify).with("You have 4 pending migrations", "").once
    MigrationTools::Tasks.any_instance.expects(:notify).with("     0 before Alpha").once
    MigrationTools::Tasks.any_instance.expects(:notify).with("     1 before Beta").once
    MigrationTools::Tasks.any_instance.expects(:notify).with("     2 change Delta").once
    MigrationTools::Tasks.any_instance.expects(:notify).with("     3        Kappa").once

    Rake::Task["db:migrate:list"].invoke
  end

  it "migrate_list_with_pending_with_group" do
    ENV['GROUP'] = 'before'

    MigrationTools::Tasks.any_instance.expects(:notify).with("You have 2 pending migrations", "before").once
    MigrationTools::Tasks.any_instance.expects(:notify).with("     0 before Alpha").once
    MigrationTools::Tasks.any_instance.expects(:notify).with("     1 before Beta").once

    Rake::Task["db:migrate:list"].invoke
  end

  it "abort_if_pending_migrations_with_group_without_migrations" do
    @task.stubs(:notify)

    begin
      Rake::Task["db:abort_if_pending_migrations:after"].invoke
    rescue SystemExit
      fail "aborted where it shouldn't"
    end
  end

  if ActiveRecord::VERSION::STRING >= "5.0.0"
    require 'active_support/testing/stream'
    include ActiveSupport::Testing::Stream
  end
  it "abort_if_pending_migrations_with_group_with_migrations" do
    lambda {
      silence_stream(STDOUT) do
        silence_stream(STDERR) do
          Rake::Task["db:abort_if_pending_migrations:before"].invoke
        end
      end
    }.must_raise(SystemExit, "did not abort")
  end

  it "migrate_group_with_group_without_pending" do
    @task.migrator(0).run
    @task.migrator(1).run

    MigrationTools::Tasks.any_instance.expects(:notify).with("Your database schema is up to date").once

    ENV['GROUP'] = 'before'
    Rake::Task["db:migrate:group"].invoke
  end

  it "migrate_group_with_pending" do
    ENV['GROUP'] = 'before'

    assert_equal 4, @task.migrator.pending_migrations.count

    Rake::Task["db:migrate:group"].invoke

    assert_equal 2, @task.migrator.pending_migrations.count
  end

  it "migrate_with_invalid_group" do
    ENV['GROUP'] = 'drunk'

    begin
      Rake::Task["db:migrate:group"].invoke
      fail "Should throw an error"
    rescue RuntimeError => e
      assert e.message =~ /Invalid group/
    end
  end

  it "convenience_list_method" do
    MigrationTools::Tasks.any_instance.expects(:notify).with("You have 2 pending migrations", "before").once
    MigrationTools::Tasks.any_instance.expects(:notify).with("     0 before Alpha").once
    MigrationTools::Tasks.any_instance.expects(:notify).with("     1 before Beta").once

    Rake::Task["db:migrate:list:before"].invoke
  end
end
