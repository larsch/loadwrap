require "test/unit"
require "loadwrap"

class TestLoadwrap < Test::Unit::TestCase
  def test_current_file
    File.open("splat.rb", "w") { |f| f.puts "print __FILE__" }
    begin
      assert_equal %x{ruby -rsplat -e 1}, LoadWrap.current_file('splat.rb')
      assert_equal %x{ruby -e "require './splat'" }, LoadWrap.current_file('splat.rb')
      path = File.basename(Dir.pwd)
      assert_equal %x{ruby -e "require '../#{path}/splat'" }, LoadWrap.current_file("../#{path}/splat.rb")
      absolute = Dir.pwd
      assert_equal %x{ruby -e "require '#{absolute}/splat'" }, LoadWrap.current_file("#{absolute}/splat.rb")
    ensure
      File.unlink("splat.rb")
    end
  end

  def test_featurep_path
    File.open("splat.rb", "w") { |f| f.puts "puts $LOADED_FEATURES;print $LOADED_FEATURES.grep(/splat\\.rb/)" }
    p %x{ ruby -e "require 'splat'; puts $LOADED_FEATURES.last" }
  end
end
