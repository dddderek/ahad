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
    desc 'Setup :test environment to use SQLite.'
    task :setsqlite => :environment do
      puts "\nSetting :test environment to use sqlite:\n\n"
      puts "Dumping mysql schema via db:dump..."
      Rake::Task['db:schema:dump'].execute
      puts "Sanitizing schema.rb of all mysql specific items that sqlite detests..."
      convert_schema_rb_from_mysql_to_sqlite(
        Rails.root.join("db", "schema.rb"))
      puts "Activating sqlite as the :test database setup in database.yml..."
      swap_active_groups_in_file(Rails.root.join("config", "database.yml"),
        ":test", ":testsqlite")
      puts "Running db:test:prepare to initialize the sqlite test database..."
      Rake::Task['db:test:prepare'].execute
      puts "Restoring the original schema.rb before sanitizing..."
      cp Rails.root.join("db", "schema.rb"), Rails.root.join("db", "schema.rb.sqlite")
      cp Rails.root.join("db", "schema.rb.bak"), Rails.root.join("db", "schema.rb")
      puts "\nAll done!  Now go test at ludicrous speed!!! [Gasp!]\n\n"
    end
  end
end