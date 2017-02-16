module UtilGlobals

  ###########################################################################
  # #shell_command?
  
  # Determines whether a shell command exists (or is installed).
  #
  # @param command [String] the command to check for, no path needed
  #
  # @return [boolean] true if command exists; false otherwise
  def shell_command?(command)
    system("which #{command} > /dev/null 2>&1")
  end  

  ###########################################################################
  # #source_for
  
  # Brings up a given object's method definition in a text editor.
  #
  # Utility function, most useful from the rails console, to 
  # find a method of an object, and the file it is defined in, and 
  # automagically open that file in an editor.  If on cloud9 it just opens
  # the file.  If on a local Ubuntu system, as long as Sublime Text is
  # installed, it will open the file right to the line that defines the
  # method.  Sweet!
  #
  # @param object [Object] the object that contains the method
  #
  # @param method_sym [Symbol] the method to be inspected
  #
  # @return [Array] [full path to file, the line in the file]
  #
  # Note, if running on cloud9, you need to first intall the
  # c9 command line tool to launch into the c9 editor from the command
  # line.  To do so:
  #   npm install c9
  # and then you may need to restart your workspace.
  # (From: http://stackoverflow.com/questions/28028178/
  #   cloud-9-how-to-open-a-file-in-the-c9-editor-from-c9-terminal)
  #
  # Thankful for Pragmatic Studio for this one:
  # https://pragmaticstudio.com/blog/2013/2/13/view-source-ruby-methods
  #
  # Tweaked to work with cloud9 by Derek Carlson 1/12/17.
  def source_for(object, method_sym)
    if shell_command?("c9") && (! File.directory?("/home/ubuntu/root") )
      puts "In order for this to work, you need to create a\n" +
           "symlink to / in your home directory, like so:\n\n" +
           "  ln -s / ~/root\n\n" +
           "Do that, then try this again.  Good luck!"
      return nil
    end
    
    if object.respond_to?(method_sym, true)
      method = object.method(method_sym)
    elsif object.is_a?(Module)
      method = object.instance_method(method_sym)
    end
    location = method.source_location
    
    if location && shell_command?("c9")
      cmd = "c9 /home/ubuntu/root#{location[0]}"
      puts "Running: #{cmd}"
      `#{cmd}`
    elsif location && shell_command?("subl")
      cmd = "subl #{location[0]}:#{location[1]}"
      puts "Running: #{cmd}"
      `#{cmd}`
    else
      puts "Can't find subl (Sublime Text) or c9 commands to run.\n" +
           "(They don't exist in your shell... e.g. `which subl` or\n" +
           " `which c9` return that the commands are not found.)\n" +
           "You can always edit this code and replace 'subl', which is\n" +
           "the command to run Sublime Text, and replace it with the\n" +
           "command for the text editor of your choice.\n\n"
    end
    location
  rescue
    nil
  end

  ###########################################################################
  # #log_paranoia_check

  # Logs a failed paranoia check, including location of failure as well
  # as location of the caller that supplied the invalid arg(s).
  #
  # @param msg [String] failure message; if possible, state clearly what
  #   was wrong with the arg, show it's invalid value, and suggest what
  #   valid looks like.  Strive to be as informative as the Rails Team. :)
  def log_paranoia_check(msg) 
    logger.warn "[PC] " + msg
    logger.warn "[PC] => At: " + caller(1).first
    logger.warn "[PC] => Called from: " + caller(2).first
  end

  ###########################################################################
  # #log_debug

  # Logs message, prepending it with the file path from rails root, the 
  # line number, and the function name where the debug message was defined.
  #
  # @param msg [String]
  def log_debug(msg)
    cc = caller(1).first.gsub(/.*\/(app\/.*)in `block in (.*)'$/, '\1\2()')
    Rails.logger.debug cc + ": " + msg
  end
end