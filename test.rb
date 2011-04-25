require 'test/unit'
require 'stringio'

require './tablecut'

class String
  def strip_spaces
    self.gsub /\s/, ''
  end
end


def run_with_arg(arg)
  old = $stdout
  $stdout = t = StringIO.new
  tablecut(arg)
  $stdout = old
  t.string
end


class TestTableCut < Test::Unit::TestCase
  def test_locals
    testdir = File.join(File.dirname(__FILE__), "test", "*")
    Dir[testdir].each do |name|
      html, expected = File.read(name).split(/EXPECTED/)
      assert_equal run_with_arg(html).strip_spaces.downcase,
                   expected.strip_spaces.downcase      
    end
  end
end
