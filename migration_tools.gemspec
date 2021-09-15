Gem::Specification.new "migration_tools", "1.6.0" do |s|
  s.description = "Rake tasks for Rails that add groups to migrations"
  s.summary  = "Encourage migrations that do not require downtime"
  s.homepage = "https://github.com/zendesk/migration_tools"
  s.email = "morten@zendesk.com"
  s.authors = ["Morten Primdahl"]
  s.files = `git ls-files lib`.split("\n")
  s.license = "Apache-2.0"

  s.add_runtime_dependency "activerecord", '>= 4.2.0', '< 6.2'

  s.add_development_dependency "rake"
  s.add_development_dependency "bump"
  s.add_development_dependency "mocha"
  s.add_development_dependency "minitest"
  s.add_development_dependency "minitest-rg"
  s.add_development_dependency "sqlite3"
  s.add_development_dependency "wwtd"
end
