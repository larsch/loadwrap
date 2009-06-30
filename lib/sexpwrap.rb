require 'loadwrap'
require 'ruby_parser'
require 'ruby2ruby'

module LoadWrap
  # Install a Sexp munging block to be called whenever code is
  # loaded via Kernel#require or Kernel#load. The block will be
  # passed the Sexp of the script (generated using ruby_parser). The
  # result of the block (value) will be the Sexp that is the actual
  # code to run. The resulting Sexp will be converted into Ruby
  # source code (using Ruby2Ruby) and eval'd and run by Ruby.
  #
  # === Example:
  #
  #   require 'sexpwrap'
  #   LoadWrapper.filter_sexp do |sexp|
  #     perform_sexp_munging(sexp)
  #   end
  def self.filter_sexp
    LoadWrap.filter_code do |code, filename|
      Ruby2Ruby.new.process(yield(RubyParser.new.parse(code, filename)))
    end
  end
end
