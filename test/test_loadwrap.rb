require "test/unit"
require "loadwrap"
require "fileutils"
include FileUtils

class TestLoadwrap < Test::Unit::TestCase

  def make_temporary_directory
    tmpbase = ENV["TEMP"] || ENV["TMP"] || "."
    tmppath = File.expand_path(File.join(tmpbase, ".tmp#{$$}"))
    mkdir_p tmppath
    return tmppath
  end

  def setup
    @original_path = Dir.getwd
    @tmppath = make_temporary_directory
    cd @tmppath
    puts @tmppath
  end

  def mkfile(filename, content)
    File.open(filename, "w") { |f| f << content }
  end

  def teardown
    cd @original_path
    rm_rf @tmppath
  end

  def test_current_file
    mkfile 'splat.rb', 'print __FILE__'
    assert_equal %x{ruby -rsplat -e 1}, LoadWrap.current_file('splat.rb')
    assert_equal %x{ruby -e "require './splat'" }, LoadWrap.current_file('splat.rb')
    path = File.basename(Dir.pwd)
    assert_equal %x{ruby -e "require '../#{path}/splat'" }, LoadWrap.current_file("../#{path}/splat.rb")
    absolute = Dir.pwd
    assert_equal %x{ruby -e "require '#{absolute}/splat'" }, LoadWrap.current_file("#{absolute}/splat.rb")
  end

  def test_featurep_path
    File.open("splat.rb", "w") { |f| f.puts "puts $LOADED_FEATURES;print $LOADED_FEATURES.grep(/splat\\.rb/)" }
    p %x{ ruby -e "require 'splat'; puts $LOADED_FEATURES.last" }
  end

  def test_load
    $loadwrap = false
    mkfile 'test.rb', '$loadwrap = true; $globalself = self'
    assert_equal true, Kernel.load('test.rb')
    assert_equal true, $loadwrap
    assert_equal eval("self.object_id", TOPLEVEL_BINDING), $globalself.object_id
  end

  def test_load_unwrapped
    mkfile 'test.rb', '$globalid1 = self.object_id'
    Kernel.loadwrap_custom_load 'test.rb'
    mkfile 'test.rb', '$globalid2 = self.object_id'
    Kernel.loadwrap_custom_load 'test.rb'

    assert_kind_of Numeric, $globalid1
    assert_kind_of Numeric, $globalid2
    assert_equal $globalid1, $globalid2
  end

  def test_load_wrapped
    mkfile 'test.rb', '$globalid1 = self.object_id; $globalstr1 = self.to_s'
    assert_equal true, Kernel.loadwrap_custom_load('test.rb')
    mkfile 'test.rb', '$globalid2 = self.object_id; $globalstr2 = self.to_s'
    assert_equal true, Kernel.loadwrap_custom_load('test.rb', true)
    
    assert_kind_of Numeric, $globalid1
    assert_kind_of Numeric, $globalid2
    assert_not_equal $globalid1, $globalid2

    assert_kind_of String, $globalstr1
    assert_kind_of String, $globalstr2
    assert_equal $globalstr1, $globalstr2
  end
end
