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

class LookupOrMethodCallTest < Sablon::TestCase
  def test_calls_method_on_object
    user = OpenStruct.new(first_name: "Jack")
    expr = Sablon::Expression.parse("user.first_name")
    assert_equal "Jack", expr.evaluate({"user" => user})
  end

  def test_calls_perform_lookup_on_hash_with_string_keys
    user = {"first_name" => "Jack"}
    expr = Sablon::Expression.parse("user.first_name")
    assert_equal "Jack", expr.evaluate({"user" => user})
  end

  def test_calls_perform_lookup_on_hash_with_symbol_keys
    skip
    user = {first_name: "Jack"}
    expr = Sablon::Expression.parse("user.first_name")
    assert_equal "Jack", expr.evaluate({"user" => user})
  end

  def test_inspect
    expr = Sablon::Expression.parse("user.first_name")
    assert_equal "«user.first_name»", expr.inspect
  end

  def test_calls_chained_methods
    user = OpenStruct.new(first_name: "Jack", address: OpenStruct.new(line_1: "55A"))
    expr = Sablon::Expression.parse("user.address.line_1")
    assert_equal "55A", expr.evaluate({ "user" => user })
  end

  def test_missing_receiver
    user = OpenStruct.new(first_name: "Jack")
    expr = Sablon::Expression.parse("user.address.line_1")
    assert_equal nil, expr.evaluate({ "user" => user })
    assert_equal nil, expr.evaluate({})
  end

end
