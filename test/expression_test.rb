require 'minitest/autorun'
require 'calculus'

class TestExpression < MiniTest::Unit::TestCase

  def test_that_it_extract_variables_properly
    assert_equal ["x", "y"], expression("x + 2^x = y").variables
  end

  def test_that_it_empty_variables_array_if_they_are_absent
    assert_equal [], expression("4 + 2^3 = 12").variables
  end

  def test_that_variables_can_be_read_using_square_brackets
    exp = expression("4 + x^3 = 12")
    exp.instance_variable_get("@variables")["x"] = 2
    assert_equal 2, exp["x"]
  end

  def test_that_variables_can_be_written_using_square_brackets
    exp = expression("4 + x^3 = 12")
    exp["x"] = 2
    assert_equal 2, exp.instance_variable_get("@variables")["x"]
  end

  def test_that_it_raises_exception_for_unexistent_variable
    exp = expression("4 + x^3 = 12")
    assert_raises(ArgumentError) { exp["y"] }
    assert_raises(ArgumentError) { exp["y"] = 3 }
  end

  def test_that_it_initializes_variables_with_nils
    exp = expression("x + 2^x = y")
    assert_nil exp["x"]
    assert_nil exp["y"]
  end

  def test_that_it_gives_access_to_postfix_notation
    exp = expression("x + 2^x = y")
    assert_equal ["x", 2, "x", :exp, :plus, "y", :eql], exp.postfix_notation
    assert_equal ["x", 2, "x", :exp, :plus, "y", :eql], exp.rpn
  end

  def test_that_it_gives_access_to_abstract_syntax_tree
    exp = expression("(2 + 3) * 4")
    assert_equal [:mul, [:plus, 2, 3], 4], exp.abstract_syntax_tree
    assert_equal [:mul, [:plus, 2, 3], 4], exp.ast
  end

  def test_that_it_gives_list_of_unbound_variables
    exp = expression("x + 2^x = y")
    assert_equal ["x", "y"], exp.unbound_variables
    exp["x"] = 3
    assert_equal ["y"], exp.unbound_variables
    exp["y"] = 2
    assert_equal [], exp.unbound_variables
  end

  def test_that_calculate_raises_unbound_variable_error_when_some_variables_missing
    assert_raises(Calculus::UnboundVariableError) { expression("x + 2 * 3").calculate }
  end

  def test_that_calculate_raises_not_implemented_error_when_detects_equation
    assert_raises(NotImplementedError) { expression("x + 2 = 7").calculate }
  end

  def test_that_it_calclulates_simple_expressions
    assert_equal 8, expression("2 \\cdot 4").calculate
    assert_equal 6, expression("2 + 2 * 2").calculate
    assert_equal 4, expression("\\frac{4}{2} * 2").calculate
    assert_equal 16, expression("4^2").calculate
  end

  def test_that_it_substitutes_variables_during_calculation
    exp = expression("2 + 2 * x")
    exp["x"] = 2
    assert_equal 6, exp.calculate
  end

  def test_that_it_refresh_sha1_sub_when_variables_get_filled
    exp = expression("2 \\cdot x = 4")
    old_sha1 = exp.sha1
    exp["x"] = 2
    refute_equal old_sha1, exp.sha1
  end

  protected

  def expression(input)
    Calculus::Expression.new(input)
  end

end
