module Calculus

  class Expression

    attr_reader :postfix_notation
    alias :rpn :postfix_notation

    attr_reader :abstract_syntax_tree
    alias :ast :abstract_syntax_tree

    def initialize(input)
      @postfix_notation = Parser.new(input).parse
      @abstract_syntax_tree = convert_to_abstract_syntax_tree
      @variables = extract_variables
    end

    def variables
      @variables.keys
    end

    def unbound_variables
      @variables.keys.select{|k| @variables[k].nil?}
    end

    def [](name)
      raise ArgumentError, "No such variable defined: #{name}" unless @variables.keys.include?(name)
      @variables[name]
    end

    def []=(name, value)
      raise ArgumentError, "No such variable defined: #{name}" unless @variables.keys.include?(name)
      @variables[name] = value
    end

    def traverse(&block)
      stack = []
      @postfix_notation.each do |node|
        case node
        when Symbol
          operation, right, left = node, stack.pop, stack.pop
          stack.push(yield(operation, left, right, stack))
        when Numeric
          stack.push(node)
        when String
          stack.push(@variables[node] || node)
        end
      end
      stack.pop
    end

    def calculate
      raise NotImplementedError, "Equation detected. This class can't calculate equations yet." if equation?
      raise UnboundVariableError, "Can't calculate. Unbound variables found: #{unbound_variables.join(', ')}" unless unbound_variables.empty?

      traverse do |operation, left, right, stack|
        case operation
        when :sqrt  then left ** (1.0 / right) # could cause some rounding errors
        when :exp   then left ** right
        when :plus  then left + right
        when :minus then left - right
        when :mul   then left * right
        when :div   then left / right
        end
      end
    end

    def equation?
      @postfix_notation.include?(:eql)
    end

    def abstract_syntax_tree
      traverse do |operation, left, right, stack|
        [operation, left, right]
      end
    end
    alias :ast :abstract_syntax_tree

    def to_s
      source
    end

    def inspect
      "#<Expression:#{@sha1} postfix_notation=#{@postfix_notation.inspect} variables=#{@variables.inspect}>"
    end

    protected

    def extract_variables
      @postfix_notation.select{|node| node.kind_of? String}.inject({}){|h, v| h[v] = nil; h}
    end

    def convert_to_abstract_syntax_tree
      traverse do |operation, left, right, stack|
        [operation, left, right]
      end
    end
  end

end
