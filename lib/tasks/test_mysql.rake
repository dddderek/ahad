require_relative '../util_rake'
include UtilRake

# From http://stackoverflow.com/questions/1325865/
#   what-is-the-standard-way-to-dump-db-to-yml-fixtures-in-rails
# With additional fix to work on cloud9 found at:
#   http://stackoverflow.com/questions/23336755/
#   activerecordadapternotspecified-database-configuration-does-not-specify-adapte
#   (search for answer with "#{Rails.env}".to_sym -- that fix did the trick. )
namespace :db do
  namespace :test do    
    desc 'Setup :test environment to use mysql.'
    task :setmysql => :environment do
      puts "\nSetting :test environment to use mysql:\n\n"
      puts "Dumping mysql schema via db:dump..."
      Rake::Task['db:schema:dump'].execute
      puts "Activating mysql as the :test database setup in database.yml..."
      swap_active_groups_in_file(Rails.root.join("config", "database.yml"),
        ":testsqlite", ":test")
      puts "Running db:test:prepare to initialize the mysql test database..."
      Rake::Task['db:test:prepare'].execute
      puts "\nAll done!  Now go test at roofied-turtle speed!!! [Yawn!]\n\n"
    end
  end
end