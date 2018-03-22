require 'test_helper'

class SablonCustomFieldHandlerTest < Sablon::TestCase
  #
  # This class supports more advanced conditional expressions and crafted
  # by @moritzgloeckl in PR #73
  class OperatorCondition < Struct.new(:conditon_expr, :block, :operation)
    def evaluate(env)
      value = conditon_expr.evaluate(env.context)
      if truthy?(operation[0..1], operation[2..-1].tr("'", ''), value.to_s)
        block.replace(block.process(env).reverse)
      else
        block.replace([])
      end
    end

    def truthy?(operation, value_a, value_b)
      case operation
      when '!='
        value_a != value_b
      when '=='
        value_a == value_b
      end
    end
  end

  # Handles conditional blocks in the template that use an operator
  class OperatorConditionalHandler
    def initialize
      @pattern = /([^ ]+):if(?:\(([^)]+)\))?/
      @op_pattern = /([^ ]+):if\(((==|!=)(\d|'[\s\S]+')+)\)/
    end

    # Returns a non-nil value if the field expression matches the pattern
    def handles?(field)
      field.expression.match(@pattern)
    end

    def build_statement(constructor, field, _options = {})
      expr_pattern = @pattern
      stmt_klass = Sablon::Statement::Condition
      #
      if field.expression =~ @op_pattern
        expr_pattern = @op_pattern
        stmt_klass = OperatorCondition
      end
      #
      expr_name, pred = field.expression.match(expr_pattern).to_a[1..2]
      block = constructor.consume_block("#{expr_name}:endIf")
      expr = Sablon::Expression.parse(expr_name)
      stmt_klass.new(expr, block, pred)
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
