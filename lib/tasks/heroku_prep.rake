require_relative '../util_rake'
include UtilRake

# From http://stackoverflow.com/questions/1325865/
#   what-is-the-standard-way-to-dump-db-to-yml-fixtures-in-rails
# With additional fix to work on cloud9 found at:
#   http://stackoverflow.com/questions/23336755/
#   activerecordadapternotspecified-database-configuration-does-not-specify-adapte
#   (search for answer with "#{Rails.env}".to_sym -- that fix did the trick. )
namespace :heroku do
  desc 'Prepare environment for a successful "git push (staging|heroku)"'
  task :prep => :environment do
    sanitize_boot_rb_for_heroku_deployment
    puts "\nDon't forget to commit and push to git before deployment."
    puts "(git needs the sanitized boot.rb so Heroku doesn't puke)\n"
    puts "\nNow go deploy like a boss!!!\n\n"
  end
end

namespace :heroku do
  desc 'Switch environment from a Heroku friendly deploy environment ' +
    ' to a development friendly local environment.'
  task :unprep => :environment do
    unsanitize_boot_rb_for_local_dev_work
    puts "\nAll done!  Go develop like a boss!!!\n\n"
  end
end

