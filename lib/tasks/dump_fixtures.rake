# From http://stackoverflow.com/questions/1325865/
#   what-is-the-standard-way-to-dump-db-to-yml-fixtures-in-rails
# With additional fix to work on cloud9 found at:
#   http://stackoverflow.com/questions/23336755/
#   activerecordadapternotspecified-database-configuration-does-not-specify-adapte
#   (search for answer with "#{Rails.env}".to_sym -- that fix did the trick. )
namespace :db do
  namespace :fixtures do    
    desc 'Create YAML test fixtures from data in an existing database.  
    Defaults to development database.  Specify RAILS_ENV=production on command line to override.'
    task :dump => :environment do
      sql  = "SELECT * FROM %s WHERE id='16494'"
      skip_tables = ["schema_info", "schema_migrations"]
      ActiveRecord::Base.establish_connection("#{Rails.env}".to_sym)
      #(ActiveRecord::Base.connection.tables - skip_tables).each do |table_name|
        table_name = "property"
        i = "000"
        File.open("#{Rails.root}/test/fixtures/#{table_name}.yml.new", 'w') do |file|
          data = ActiveRecord::Base.connection.select_all(sql % table_name)
          file.write data.inject({}) { |hash, record|
            hash["#{table_name}_#{i.succ!}"] = record
            hash
          }.to_yaml
        end
      #end
    end
  end
end