# -*- coding: utf-8 -*-
require "test_helper"

class ExpressionTest < Sablon::TestCase
end

class VariableExpressionTest < Sablon::TestCase
  def test_lookup_the_variable_in_the_context
    expr = Sablon::Expression.parse("first_name")
    assert_equal "Jane", expr.evaluate({"first_name" => "Jane", "last_name" => "Doe"})
  end

  def test_inspect
    expr = Sablon::Expression.parse("first_name")
    assert_equal "«first_name»", expr.inspect
  end
end

class SimpleMethodCallTest < Sablon::TestCase
  def test_calls_method_on_context_variable
    user = OpenStruct.new(first_name: "Jack")
    expr = Sablon::Expression.parse("user.first_name")
    assert_equal "Jack", expr.evaluate({"user" => user})
  end

  def test_inspect
    expr = Sablon::Expression.parse("user.first_name")
    assert_equal "«user.first_name»", expr.inspect
  end
end
