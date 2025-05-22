# Migration Tools  [![Build Status](https://github.com/zendesk/migration_tools/workflows/CI/badge.svg)](https://github.com/zendesk/migration_tools/actions?query=workflow%3ACI)

Rake tasks for grouping migrations.

## Groups

The migration tools allow you to specify a group in your migrations. This is used to allow you to run your migrations in groups, as opposed to all at once. This is useful if you want to run a certain group of migrations before a deploy, another group during deploy and a third group after deploy.

We use this technique to be able to QA new production code in an isolated environment that runs against the production database. It also reduces the number of moving parts come deploy time, which is helpful when you're doing zero downtime deploys.

You specify which group a migration belongs to inside the migration, like so:

```ruby
  class CreateHello < ActiveRecord::Migration
    group :before

    def self.up
      ...
    end
  end
```

The names of the possible groups are predefined to avoid turning this solution in to a generic hammer from hell. You can use the following groups: before, during, after, change. We define these as:

*before* this is for migrations that are safe to run before a deploy of new code, e.g. adding columns/tables

*during* this is for migrations that require the data structure and code to deploy "synchronously"

*after* this is for migrations that should run after the new code has been pushed and is running

*change* this is a special group that you run whenever you want to change DB data which you'd otherwise do in script/console

## Commands

The list commands

```
  $ rake db:migrate:list - shows pending migrations by group
  $ rake db:migrate:list:before - shows pending migrations for the before group
  $ rake db:migrate:list:during - shows pending migrations for the during group
  $ rake db:migrate:list:after  - shows pending migrations for the after group
  $ rake db:migrate:list:change - shows pending migrations for the change group
```

The group commands

```
  $ GROUP=before rake db:migrate:group - runs the migrations in the specified group
  $ rake db:migrate:group:before - runs pending migrations for the before group
  $ rake db:migrate:group:during - runs pending migrations for the during group
  $ rake db:migrate:group:after  - runs pending migrations for the after group
  $ rake db:migrate:group:change - runs pending migrations for the change group
```
Note that rake db:migrate is entirely unaffected by this.

### Releasing a new version
A new version is published to RubyGems.org every time a change to `version.rb` is pushed to the `main` branch.
In short, follow these steps:
1. Update `version.rb`,
2. update version in all `Gemfile.lock` files,
3. merge this change into `main`, and
4. look at [the action](https://github.com/zendesk/migration_tools/actions/workflows/publish.yml) for output.

To create a pre-release from a non-main branch:
1. change the version in `version.rb` to something like `1.2.0.pre.1` or `2.0.0.beta.2`,
2. push this change to your branch,
3. go to [Actions → “Publish to RubyGems.org” on GitHub](https://github.com/zendesk/migration_tools/actions/workflows/publish.yml),
4. click the “Run workflow” button,
5. pick your branch from a dropdown.

## License

Copyright 2015 Zendesk

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
