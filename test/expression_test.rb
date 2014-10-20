# -*- coding: utf-8 -*-
require "test_helper"

class ExpressionTest < Sablon::TestCase
  def test_variable_expression
    expr = Sablon::Expression.parse("first_name")
    assert_equal "Jane", expr.evaluate({"first_name" => "Jane", "last_name" => "Doe"})
  end

  def test_simple_method_call
    user = OpenStruct.new(first_name: "Jack")
    expr = Sablon::Expression.parse("user.first_name")
    assert_equal "Jack", expr.evaluate({"user" => user})
  end
end
