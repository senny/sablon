require 'test_helper'

class SablonCustomFieldHandlerTest < Sablon::TestCase
  #
  # This class supports more advanced conditional expressions and crafted
  # by @moritzgloeckl in PR #73
  class OperatorCondition < Sablon::Statement::Condition
    def eval_conditional_blocks(env)
      #
      # evaluate each expression until a true one is found, false blocks
      # are cleared from the document.
      until @conditions.empty?
        condition = @conditions.shift
        conditon_expr = condition[:condition_expr]
        predicate = condition[:predicate]
        block = condition[:block]
        #
        # determine value of conditional expression + predicate
        value = eval_condition_expr(conditon_expr, predicate, env.context)
        #
        # manipulate block based on truthy-ness of value
        if truthy?(value)
          block.replace(block.process(env).reverse)
          break true
        else
          block.replace([])
        end
      end
    end

    def eval_condition_expr(conditon_expr, predicate, context)
      value = conditon_expr.evaluate(context)
      #
      if predicate.to_s =~ /^[!=]=/
        operator = predicate[0..1]
        cmpr_val = predicate[2..-1].tr("'", '')
        compare_values(value.to_s, cmpr_val, operator)
      elsif predicate
        value.public_send(predicate)
      else
        value
      end
    end

    def compare_values(value_a, value_b, operator)
      case operator
      when '!='
        value_a != value_b
      when '=='
        value_a == value_b
      end
    end
  end

  # Handles conditional blocks in the template that use an operator
  class OperatorConditionalHandler < Sablon::Processor::Document::ConditionalHandler
    def build_statement(constructor, field, _options = {})
      expr_name = field.expression.match(@pattern).to_a[1]
      args = [
        # end expression (first arg)
        "#{expr_name}:endIf",
        # sub block patterns to check for
        /(#{expr_name}):els[iI]f(?:\(([^)]+)\))?/,
        /(#{expr_name}):else/
      ]
      blocks = process_blocks(constructor.consume_multi_block(*args))
      OperatorCondition.new(blocks)
    end
  end

  def setup
    super
    @base_path = Pathname.new(File.expand_path('../', __FILE__))
    @template_path = @base_path + 'fixtures/custom_field_handlers_template.docx'
    @output_path = @base_path + 'sandbox/custom_field_handlers.docx'
    @sample_path = @base_path + 'fixtures/custom_field_handlers_sample.docx'
    #
    # register new handlers to allow insertion without equals sign and
    # advanced conditionals
    klass = Sablon::Processor::Document
    @orig_conditional_handler = klass.remove_field_handler :conditional
    klass.register_field_handler :default, klass.field_handlers[:insertion]
    klass.register_field_handler :conditional, OperatorConditionalHandler.new
  end

  def teardown
    # remove extra handlers
    Sablon::Processor::Document.remove_field_handler :default
    Sablon::Processor::Document.replace_field_handler :conditional, @orig_conditional_handler
  end

  def test_generate_document_from_template
    template = Sablon.template @template_path
    context = {
      normal_field: 'success1',
      no_leading_equals: 'success2',
      inside_if_no_op: 'success3',
      no_operator: OpenStruct.new(test: 'success4'),
      equals_operator: 'test',
      inside_if_equals_op: 'success5'
    }
    #
    template.render_to_file @output_path, context
    assert_docx_equal @sample_path, @output_path
  end
end
