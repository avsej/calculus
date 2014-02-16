require 'minitest/autorun'
require 'calculus'

class TestParser < MiniTest::Test

  def test_that_it_parses_simple_arithmetic
    assert_equal [1, 2, :plus], parse("1+2")
  end

  def test_that_it_skips_spaces
    assert_equal [1, 2, :plus], parse("1 + 2")
    assert_equal [4, 2, :exp], parse(" 4 ^ 2 ")
    assert_equal [4, 2, :sqrt], parse("\\sqrt [  2 ] { 4  }")
    assert_equal [5, 4, :div], parse("\\frac {  5 } { 4  }")
  end

  def test_that_it_properly_parses_square_root
    assert_equal [2, 4, 2, :sqrt, :mul], parse("2 * \\sqrt{4}")
    assert_equal [8, 3, :sqrt], parse("\\sqrt[3]{8}")
    assert_equal [8, 3, 2, :plus, :sqrt], parse("\\sqrt[3+2]{8}")
  end

  def test_that_it_properly_parses_fractions
    assert_equal [8, 3, :div], parse("\\frac{8}{3}")
    assert_equal [3, 1, :plus, 3, 1, :minus, :div], parse("\\frac{3+1}{3-1}")
    assert_equal [3, 1, :plus, 3, 1, :minus, 4, :mul, :div], parse("\\frac{3+1}{(3-1)*4}")
  end

  def test_that_it_honours_priorities
    assert_equal [3, 2, 2, :mul, :plus], parse("3+2*2")
    assert_equal [3, 5, 4, :exp, :mul, 2, :plus], parse("3*5^4+2")
    assert_equal [3, 5, :mul, 4, :exp, 2, :plus], parse("(3*5)^4+2")
    assert_equal [3, 5, :mul, 2, :sqrt, 2, :plus], parse("\\sqrt{3*5}+2")
  end

  def test_that_it_allows_parentesis
    assert_equal [3, 2, :plus, 2, :mul], parse("(3+2)*2")
    assert_equal [3, 2, :plus, 2, :mul], parse("\\left(3+2\\right)*2")
  end

  def test_that_it_properly_parses_floats
    assert_equal [1.2], parse("1.2")
    assert_equal [1.2e10], parse("1.2e10")
    assert_equal [1.2e-10], parse("1.2e-10")
  end

  def test_that_it_allows_nesting
    assert_equal [8, 2, :sqrt, 3, :div], parse("\\frac{\\sqrt{8}}{3}")
    assert_equal [4, 8, 3, :div, :sqrt], parse("\\sqrt[\\frac{8}{3}]{4}")
  end

  def test_that_it_recognizes_equals_sign
    assert_equal [2, 4, :mul, 2, :div, 16, 2, :sqrt, :eql], parse("2 \\cdot \\frac{4}{2} = \\sqrt{16}")
  end

  def test_that_it_recognizes_variables
    assert_equal [2, "x", :mul, 16, :eql], parse("2 \\cdot x = 16")
    assert_equal [2, "x_i", :mul, 16, :eql], parse("2 \\cdot x_i = 16")
    assert_equal [2, "x_2", :mul, 16, :eql], parse("2 \\cdot x_2 = 16")
    assert_equal [2, "x2", :mul, 16, :eql], parse("2 \\cdot x2 = 16")
    assert_raises(Calculus::ParserError) { assert_equal [2, "x__2", :mul, 16, :eql], parse("2 \\cdot x__2 = 16") }
  end

  def test_that_it_handles_unary_minus
    assert_equal [2, :uminus], parse("-2")
    assert_equal [2, :uminus, 2, :uminus, :mul], parse("-2 * -2")
  end

  protected

  def parse(input)
    Calculus::Parser.new(input).parse
  end

end
