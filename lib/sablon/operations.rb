# -*- coding: utf-8 -*-
module Sablon
  module Statement
    class Insertion < Struct.new(:expr, :field)
      def evaluate(env)
        if content = expr.evaluate(env.context)
          field.replace(Sablon::Content.wrap(content), env)
        else
          field.remove
        end
      end
    end

    class Loop < Struct.new(:list_expr, :iterator_name, :block)
      def evaluate(env)
        value = list_expr.evaluate(env.context)
        value = value.to_ary if value.respond_to?(:to_ary)
        raise ContextError, "The expression #{list_expr.inspect} should evaluate to an enumerable but was: #{value.inspect}" unless value.is_a?(Enumerable)

        content = value.flat_map do |item|
          iter_env = env.alter_context(iterator_name => item)
          block.process(iter_env)
        end
        update_unique_ids(env, content)
        block.replace(content.reverse)
      end

      private

      # updates all unique id's present in the xml being copied
      def update_unique_ids(env, content)
        doc_xml = env.document.zip_contents[env.document.current_entry]
        dom_entry = env.document[env.document.current_entry]
        #
        # update all docPr tags created
        selector = "//*[local-name() = 'docPr']"
        init_id_val = dom_entry.max_attribute_value(doc_xml, selector, 'id')
        update_tag_attribute(content, 'docPr', 'id', init_id_val)
        #
        # update all cNvPr tags created
        selector = "//*[local-name() = 'cNvPr']"
        init_id_val = dom_entry.max_attribute_value(doc_xml, selector, 'id')
        update_tag_attribute(content, 'cNvPr', 'id', init_id_val)
      end

      # Increments the attribute value of each element with the id by 1
      def update_tag_attribute(content, tag_name, attr_name, init_val)
        content.each do |nodeset|
          nodeset.xpath(".//*[local-name() = '#{tag_name}']").each do |node|
            node[attr_name] = (init_val += 1).to_s
          end
        end
      end
    end

    class Condition
      def initialize(conditions)
        @conditions = conditions
        @else_block = nil
        return unless @conditions.last[:block].start_field.expression =~ /:else/
        #
        # store the else block separately because it is always "true"
        @else_block = @conditions.pop[:block]
      end

      def evaluate(env)
        #
        # process conditional blocks, if and elsif(s)
        any_true = eval_conditional_blocks(env)
        #
        # clear the blocks for any remaining conditions
        @conditions.map { |cond| cond.block.replace([]) }
        return unless @else_block
        #
        # apply the else clause if none of the conditions were true
        if any_true
          @else_block.replace([])
        elsif @else_block
          @else_block.replace(@else_block.process(env).reverse)
        end
      end

      private

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
          # fetch value optionally calling a predicate method
          value = conditon_expr.evaluate(env.context)
          value = value.public_send(predicate) if predicate
          #
          if truthy?(value)
            block.replace(block.process(env).reverse)
            break true
          else
            block.replace([])
          end
        end
      end

      def truthy?(value)
        case value
        when Array
          !value.empty?
        else
          value ? true : false
        end
      end
    end

    class Comment < Struct.new(:block)
      def evaluate(_env)
        block.replace []
      end
    end

    class Image < Struct.new(:image_reference, :block)
      def evaluate(env)
        image = image_reference.evaluate(env.context)
        set_local_rid(env, image) if image
        block.replace(image)
      end

      private

      def set_local_rid(env, image)
        if image.rid_by_file.keys.empty?
          # Only add the image once, it is reused afterwards
          rel_attr = {
            Type: 'http://schemas.openxmlformats.org/officeDocument/2006/relationships/image'
          }
          rid = env.document.add_media(image.name, image.data, rel_attr)
          image.rid_by_file[env.document.current_entry] = rid
        elsif image.rid_by_file[env.document.current_entry].nil?
          # locate an existing relationship and duplicate it
          entry = image.rid_by_file.keys.first
          value = image.rid_by_file[entry]
          #
          rel = env.document.find_relationship_by('Id', value, entry)
          rid = env.document.add_relationship(rel.attributes)
          image.rid_by_file[env.document.current_entry] = rid
        end
        #
        image.local_rid = image.rid_by_file[env.document.current_entry]
      end
    end
  end

  module Expression
    class Variable < Struct.new(:name)
      def evaluate(context)
        context[name]
      end

      def inspect
        "«#{name}»"
      end
    end

    class LookupOrMethodCall < Struct.new(:receiver_expr, :expression)
      def evaluate(context)
        if receiver = receiver_expr.evaluate(context)
          expression.split(".").inject(receiver) do |local, m|
            case local
            when Hash
              local[m]
            else
              local.public_send m if local.respond_to?(m)
            end
          end
        end
      end

      def inspect
        "«#{receiver_expr.name}.#{expression}»"
      end
    end

    def self.parse(expression)
      if expression.include?(".")
        parts = expression.split(".")
        LookupOrMethodCall.new(Variable.new(parts.shift), parts.join("."))
      else
        Variable.new(expression)
      end
    end
  end
end
