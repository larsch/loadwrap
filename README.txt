= loadwrap

* http://github.com/larsch/loadwrap

== DESCRIPTION:

Wraps loading of Ruby code (Through Kernel#require and Kernel#load)
with your own methods that can change the code before it is parsed and
run by the Ruby interpreter.

== FEATURES/PROBLEMS:

* $LOADED_FEATURES and $" are updated prior to evaluating the
  contents of a script. The MRI behaviour is to update it after the
  script is evaluated.

== SYNOPSIS:

Intercepting loading of scripts from the file system using LoadWrap.loadwrap:

  require 'loadwrap'
  LoadWrap.loadwrap do |filename|
    File.read(filename)
  end

Intercepting parsing of scripts using LoadWrap.filter_code:
  
  require 'loadwrap'
  LoadWrap.filter_code do |code|
    code_munging_method(code)
  end

Intercepting parsetrees using LoadWrap.filter_code (Requires ruby_parser and Ruby2Ruby gems):

  require 'sexpwrap'
  LoadWrap.filter_sexp do |code|
    sexp_munging_method(code)
  end

== REQUIREMENTS:

* ruby_parser (optional)
* Ruby2Ruby (optional)
* sexp_processor (optional)

== INSTALL:

* gem install loadwrap

== LICENSE:

(The MIT License)

Copyright (c) 2009 Lars Christensen

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
