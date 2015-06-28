require './workers'
require 'resque/tasks'
require 'yaml'
require 'active_record'

namespace :db do

  desc 'Load database configuration into @database_configuration.'
  task :database_configuration do
    @database_configuration = YAML::load(File.open('database.yml'))
  end

  desc 'Connect to database using @database_configuration.'
  task :connect => :database_configuration do
    ActiveRecord::Base.establish_connection(@database_configuration)
  end

  desc 'Migrate database.'
  task :migrate => :connect do
    ActiveRecord::Migration.verbose = true
    ActiveRecord::Migrator.migrate('db/migrate')
  end

end

namespace :workers do
  desc 'Start scrapers.'
  task :work do
    Resque.enqueue(TermsScraperJob)
  end
end
