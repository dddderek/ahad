namespace :test do
  desc 'Run rspec full test suite using xvfb.'
  task :c9 => :environment do
    puts "\nRunning test suite using xvfb-run so it works on Cloud9...\n"
    cmd = "cd ~/workspace/ahad_website/ && " +
      "xvfb-run bundle exec spring rspec spec --format doc"
    print "Running: "
    sh(cmd)
  end
end

namespace :test do
  desc 'Run rspec full test suite regularly, using a visible Firefox.'
  task :reg => :environment do
    puts "\nRunning test suite without xvfb-run so Firefox pops up...\n"
    cmd = "cd ~/workspace/ahad_website/ && " +
      "bundle exec spring rspec spec --format doc"
    print "Running: "
    sh(cmd)
  end
end
