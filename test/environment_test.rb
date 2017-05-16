# -*- coding: utf-8 -*-
require "test_helper"

class EnvironmentTest < Sablon::TestCase
  def test_transforms_internal_hash
    context = Sablon::Context.transform_hash(a: 1, b: { c: 2, "d" => 3 })
    env = Sablon::Environment.new(nil, a: 1, b: { c: 2, "d" => 3 })
    #
    assert_equal(env.template, nil)
    assert_equal(context, env.context)
  end

  def test_alter_context
    # set initial context
    env = Sablon::Environment.new(nil, a: 1, b: { c: 2, "d" => 3 })
    # alter context to change a single key and set a new one
    env2 = env.alter_context(a: "a", e: "new-key")
    assert_equal({ "a" => "a", "b" => { "c" => 2, "d" => 3 }, "e" => "new-key" }, env2.context)
    # check that the old context was not modified
    assert_equal({"a" => 1, "b" => { "c" => 2, "d" => 3 }}, env.context)
    # check that numbering and template are the same references
    assert env.template.equal?(env2.template), "#{env.template} != #{env2.template}"
    assert env.numbering.equal?(env2.numbering), "#{env.numbering} != #{env2.numbering}"
    # check that a new context reference was created
    assert !env.context.equal?(env2.context), "#{env.context} == #{env2.context}"
  end
end
