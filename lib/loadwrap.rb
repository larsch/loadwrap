require 'pathname'

# LoadWrap enables munging of scripts before they are parsed and
# run by Ruby. It hooks into Ruby's require and load methods and calls
# back to your own filter methods with the contents of the
# script. Your filter methods can then change the script in any way
# and return the script to be actually loaded and run by Ruby.
#
# == Example:
#
#  LoadWrap.filter_code do |code|
#     perform_code_munging(code)
#  end

module LoadWrap
  @filters = []
  @loadwrap = proc { |filename| File.read(filename) }

  # LoadWrap version number.
  VERSION = "0.0.1"

  class UnhandledPath < RuntimeError
  end
  
  class << self

    # Install a code munging block to be called whenever code is
    # loaded via Kernel#require or Kernel#load. The block will be
    # passed the contents of the script (Ruby source code) and
    # optionally the filename of the script being loaded. The result
    # of the block (value) will be the actual script that is parsed
    # and run by Ruby.
    #
    # === Example:
    #
    #   LoadWrap.filter_code do |code, filename|
    #     if filename =~ /somepattern/
    #       perform_code_munging(code)
    #     end
    #   end
    def filter_code(&block)
      @filters.push(block)
    end

    # Install a code loading block to be called whenever code is
    # loaded via Kernel#require or Kernel#load. The block is passed
    # the name of the file to be loaded and must evaluate to the Ruby
    # source code to be evalutated. Only 1 of these blocks can be
    # installed at one time. Calling this method multiple times will
    # replace previously installed wrappers. Filters installed using
    # filter_code or filter_sexp will still be called when loadwrap
    # hooks are installed. The default loadwrap handler is simply
    # calls File.read.
    #
    # === Example:
    #
    #   LoadWrap.loadwrap do |filename|
    #     File.read(filename)
    #   end
    def loadwrap(&block)
      @loadwrap = block
    end

    # Load, munge, and run a file. Passes the file through the
    # loadwrap handler and the contents through each of the installed
    # filters (filter_code and filter_sexp).
    def custom_load(filename) #:nodoc:
      code = @loadwrap.call(filename)
      code = @filters.inject(code) { |memo, filter|
        raise UnhandledPath if memo.nil?
        if filter.arity == 2
          filter.call(memo, filename)
        else
          filter.call(memo)
        end
      }
      raise UnhandledPath if code.nil?
      eval code, TOPLEVEL_BINDING, current_file(filename)
    end

    # Find a file in the Ruby search patch or relative to the current
    # path.
    def search_path(filename) #:nodoc:
      if File.file?(filename)
        return filename
      else
        $:.each do |pth|
          fpth = File.join(pth, filename)
          return fpth if File.file?(fpth)
        end
      end
      nil
    end

    # Given an absolute path and the filename originally require'd,
    # returns the path that would be inserted in
    # $LOADED_FEATURES/$". The Ruby 1.8 version returns the
    # filename, unchanged.
    def featurep_path_ruby18(path, filename) #:nodoc:
      filename
    end

    # Given a filename (as required, but with extension), return the
    # filename that will be used when eval'ing the file and which is
    # also available as __FILE__. The Ruby 1.8 returns the relative
    # patch (unless absolute) prefixed by './', except if the path
    # starts with '..'.
    def current_file_ruby18(filename) #:nodoc:
      if Pathname.new(filename).absolute?
        filename
      else
        if filename =~ /^\.\.?\//
          filename
        else
          File.join('.', filename)
        end
      end
    end
      
    # Given an path and the filename originally require'd, returns
    # the path that would be inserted in $LOADED_FEATURES/$". The
    # Ruby 1.9 version returns the expanded full path.
    def featurep_path_ruby19(path, filename) #:nodoc:
      File.expand_path(path)
    end

    # Given a filename (as required, but with extension), return the
    # filename that will be used when eval'ing the file and which is
    # also available as __FILE__. The Ruby 1.9 version returns the
    # absolute and expanded path.
    def current_file_ruby19(filename) #:nodoc:
      dfile = File.expand_path(filename)
    end
    
    if RUBY_VERSION =~ /^1\.8\./
      alias featurep_path featurep_path_ruby18
      alias current_file current_file_ruby18
    else
      alias featurep_path featurep_path_ruby19
      alias current_file current_file_ruby19
    end

    # Determines if a given path (including load path) and filename
    # (as require'd) is already loaded.
    def feature_p(path, filename) #:nodoc:
      $LOADED_FEATURES.include?(featurep_path(path, filename))
    end

    # Custom require method (called by Kernel#require). This search
    # for the specified file in the load path and adds optional '.rb'
    # to the filename. If the script is not found, it invokes the
    # original Kernel#require method (As
    # Kernel#loadwrap_original_require).
    def custom_require(filename) #:nodoc:
      if path = search_path(filename)
        return false if feature_p(path, filename)
        if filename =~ /\.rb$/
          # p [:insert, featurep_path(path, filename)]
          $".push(featurep_path(path, filename))
          custom_load(path)
        else
          loadwrap_original_require(filename)
        end
      else
        rbfilename = filename + '.rb'
        if path = search_path(rbfilename)
          return false if feature_p(path, rbfilename)
          # p [:insert, featurep_path(path, rbfilename)]
          $".push(featurep_path(path, rbfilename))
          begin
            custom_load(path)
          rescue UnhandledPath
            $".pop
            loadwrap_original_require(filename)
          end
        else
          loadwrap_original_require(filename)
        end
      end
    end
  end
end

module Kernel #:nodoc:

  # Custom require method. This will is aliased to Kernel#require.
  def loadwrap_custom_require(filename)
    LoadWrap.custom_require(filename)
  end

  # Custom load method. This will is aliased to Kernel#load.
  def loadwrap_custom_load(filename)
    LoadWrap.custom_load(filename)
  end

  if respond_to?(:gem_original_require)
    alias loadwrap_original_require gem_original_require
    # Inject LoadWrap below RubyGems
    alias gem_original_require loadwrap_custom_require
  else
    alias loadwrap_original_require require
    # Install wrapper for require
    alias require loadwrap_custom_require
  end

  alias loadwrap_original_load load
  alias load loadwrap_custom_load
end
