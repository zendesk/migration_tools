Gem::Specification.new "migration_tools", "1.0.0" do |s|
  s.description = "Rake tasks for Rails that add groups to migrations"
  s.summary  = "Encourage migrations that do not require downtime"
  s.homepage = "http://github.com/morten/migration_tools"
  s.email = "morten@zendesk.com"
  s.authors = ["Morten Primdahl"]
  s.files = `git ls-files`.split("\n")
  s.license = "Apache License Version 2.0"
  s.add_runtime_dependency "activerecord"
end
