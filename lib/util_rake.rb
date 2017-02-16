module UtilRake
  require 'fileutils'

  # Convert db/schema.rb from mysql format to a format that can
  # db:test:prepare can use to initialize an SQLite database.
  # 
  # Despite Rails documentation that says that the schema.rb file
  # is database agnostic, turns out, as per a Rails dev, "Oh,
  # that hasn't been the case for a long time."  Thus, this routine
  # is a total hack... it deletes all the text between quotes for
  # :options (because they contain mysql specific settings), and
  # it comments out all added indexes (t.index...), because
  # when running db:test:prepare for sqlite, it errors out saying
  # "index already created".  I don't understand it, but commenting
  # them out works and allows an sqlite database to be initialized.
  # Not sure if the indexes are maintained or not, but since the
  # test database uses minimal data, full table searches probably
  # aren't going to take any time at all.
  #
  # @param path_and_file [String] to schema.rb file.
  #
  # Side Effect: schema.rb gets in-place transformed into
  #   a sqlite-palatable format, and the source schema.rb
  #   gets backed up to schema.rb.bak
  #
  # @author Derek Carlson <carlson.derek@gmail.com>
  def convert_schema_rb_from_mysql_to_sqlite(path_and_file)

    file_name = File.basename path_and_file
    path = File.dirname path_and_file

    FileUtils.cp path_and_file, File.join(path, file_name + ".bak")

    a_out = []
    text = File.read(path_and_file)
    text.each_line do |line|
      # Remove options, e.g.
      #  create_table "TESTnotesource", id: :integer, force: :cascade, 
      #    options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
      # Becomes...
      #  create_table "TESTnotesource", id: :integer, force: :cascade, 
      #    options: "" do |t|
      line.gsub!(/^(.*options: ").*(".*)$/,'\1\2')
      # Comment out all t.index calls
      #      t.index ["propid"], name: "propid", using: :btree
      # Becomes...
      #   #   t.index ["propid"], name: "propid", using: :btree
      line.gsub!(/^(\s*t\.index.*)$/,'#\1')
      a_out << line
    end
    
    File.open(path_and_file, "w") { |file| file.puts a_out }
  end
  
  # Given a file (originally used for database.yml) that contains
  # two mutually exclusive sets of lines, such as:
  #
  #     #test:                           # :test
  #     #  <<: *default                  # :test
  #     #  database: altaheri_djrtest    # :test
  #
  #     test:                           # :testsqlite
  #       adapter: sqlite3              # :testsqlite
  #       pool: 5                       # :testsqlite
  #
  # this routine can deactivate (comment out) lines that match
  # a certain tag, and activate (remove '#' at start of line) lines
  # that match a different tag.
  #
  # In the case above, the group of lines tagged "# :test" are currently
  # commented out, so they will be activated by removing the first "#" on
  # those lines.  
  #
  # The group of lines tagged "# :testsqlite" are currently active or 
  # 'live', so they will be deactivated by having a "#" added as the first
  # character on each tagged line.
  #
  # Thus, running the following commmand:
  #
  #   swap_active_groups_in_file(Rails.root.join("config", "database.yml"),
  #      ":testsqlite", ":test")
  #
  # is going to deactivate ":testsqlite" lines and activate ":test" lines, 
  # resulting in the database.yml file being in-place transformed to:
  #
  #     test:                           # :test
  #       <<: *default                  # :test
  #       database: altaheri_djrtest    # :test
  #
  #     #test:                           # :testsqlite
  #     #  adapter: sqlite3              # :testsqlite
  #     #  pool: 5                       # :testsqlite
  #
  # This should work for any text file as long as you have the tags as the
  # last things on the line with no other words after them.
  #
  # @param path_and_file [String] the text file you want to transform
  #
  # @param tag_to_deactivate [String] the tag name, including the leading ":",
  #   of the lines you want commented out.
  #
  # @param tag_to_activate [String] the tag name, including the leading ":",
  #   of the lines you want activated (comments removed)
  #
  # Side Effect: the file gets in-place transformed and the source file
  #   gets backed up to [filename.ext].bak
  #
  # @author Derek Carlson <carlson.derek@gmail.com>
  def swap_active_groups_in_file(path_and_file, tag_to_deactivate, tag_to_activate)
    
    file_name = File.basename path_and_file
    path = File.dirname path_and_file

    FileUtils.cp path_and_file, File.join(path, file_name + ".bak")

    a_out = []
    text = File.read(path_and_file)
    if false
        puts "Text: " + text
        puts "Deactivating (commenting out) tag: " + tag_to_deactivate
        puts "Activating (uncommenting) tag: " + tag_to_activate
    end
    text.each_line do |line|
      # Deactivate (comment out)
      line.gsub!(/^([^#].*#\s*#{Regexp.quote(tag_to_deactivate)}\s*$)/,'#\1')
      # Activate (uncomment)
      line.gsub!(/^#([^#].*#\s*#{Regexp.quote(tag_to_activate)}\s*$)/,'\1') 
      a_out << line
    end
    
    File.open(path_and_file, "w") {|file| file.puts a_out }
  end
  
  # Ensure that the benchmark code in boot.rb is commented
  # out so that the app works with Heroku.  Otherwise it
  # fails on deployment saying there's a problem with
  # pry-byebug.
  #
  # boot.rb is modified in place, and a backup is made
  # named boot.rb.bak.
  def sanitize_boot_rb_for_heroku_deployment()

    path_and_file = Rails.root.join("config", "boot.rb")
    file_name = File.basename path_and_file
    path = File.dirname path_and_file

    FileUtils.cp path_and_file, File.join(path, file_name + ".bak")

    # Note, it seems a bit backwards, because we sanitize boot.rb
    # by wrapping all the Heroku-no-likey stuff in a =begin =end
    # comment block.  Normally the comment block - the =begin
    # and =end - are commented out, because I DO want to run the
    # benchmark code during development.  But we need to REMOVE
    # the leading "#" before =begin and =end so that they become
    # live code and actually comment out all the benchmark stuff.
    # So, we remove the comments on the comments so it all can
    # be commented out.  How's that for a brain bender?
    tag_to_activate = ":rake-automated-do-not-remove-this"
    
    a_out = []
    text = File.read(path_and_file)
    text.each_line do |line|
      line.gsub!(/^#([^#].*#\s*#{Regexp.quote(tag_to_activate)}\s*$)/,'\1') 
      a_out << line
    end
    
    File.open(path_and_file, "w") { |file| file.puts a_out }
  end

  # See comments above to sanitize_boot_rb_for_heroku_deployment()
  # This just undoes what that routine does.
  def unsanitize_boot_rb_for_local_dev_work()

    path_and_file = Rails.root.join("config", "boot.rb")
    file_name = File.basename path_and_file
    path = File.dirname path_and_file

    FileUtils.cp path_and_file, File.join(path, file_name + ".bak")

    tag_to_deactivate = ":rake-automated-do-not-remove-this"
    
    a_out = []
    text = File.read(path_and_file)
    text.each_line do |line|
      line.gsub!(/^([^#].*#\s*#{Regexp.quote(tag_to_deactivate)}\s*$)/,'#\1')
      a_out << line
    end
    
    File.open(path_and_file, "w") { |file| file.puts a_out }
  end
  
end
