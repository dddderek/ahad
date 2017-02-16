source 'https://rubygems.org'

gem 'rails',        '5.0.0.1'
gem 'responders',   '2.3.0'
gem 'puma',         '3.4.0'
gem 'sass-rails',   '5.0.6'
gem 'uglifier',     '3.0.0'
gem 'coffee-rails', '4.2.1'
gem 'jquery-rails', '4.1.1'
gem 'turbolinks',   '5.0.1'
gem 'jbuilder',     '2.4.1'
gem 'redcarpet',    '~> 3.0.0'
gem 'normalize-scss', '~> 4.0', '>= 4.0.3'
gem 'activemodel-serializers-xml'
gem 'draper', github: 'drapergem/draper'
gem 'fuzzy-string-match'

group :development, :test do
  gem 'byebug',  '9.0.0', platform: :mri
  gem 'spring-commands-rspec'
  gem 'rspec-rails', '~> 3.5'
  gem 'guard-rspec'
  gem 'capybara', '~> 2.5'
  gem 'selenium-webdriver'
  gem 'factory_girl_rails', '~> 4.5.0'
  gem 'database_cleaner', '1.3.0'
end

group :development, :test, :production do
  gem 'mysql2', '>= 0.3.18', '< 0.5'
end

group :development do
  gem 'web-console',           '3.1.1'
  gem 'listen',                '3.0.8'
  gem 'spring',                '1.7.2'
  gem 'spring-watcher-listen', '2.0.0'
  gem 'pry-byebug'
end

group :test do
  gem 'sqlite3'
  gem 'rails-controller-testing', '0.1.1'
  gem 'minitest-reporters',       '1.1.9'
  gem 'guard',                    '2.13.0'
  gem 'guard-minitest',           '2.4.4'
end

group :production do
#  gem 'pg', '0.18.4'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]