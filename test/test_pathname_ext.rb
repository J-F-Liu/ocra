require File.join(File.dirname(__FILE__), 'helper')

require 'ocra/ext/pathname'

class PathnameExt_test < Test::Unit::TestCase

  def test_basic

    p1 = Pathname.new("/usr")
    p2 = Pathname.new("/usr/share/applications")

    assert p2.subpath?(p1)
    assert !p1.subpath?(p2)

    #assert_equal [], p2.find_all_files(/mail/)

  end
end