require 'digest/sha1'

module Calculus

  class Expression
    include Latex

    attr_reader :sha1
    attr_reader :source

    attr_reader :postfix_notation
    alias :rpn :postfix_notation

    def initialize(source)
      @postfix_notation = Parser.new(@source = source).parse
      raise ArgumentError, "Should be no more that one equals sign" if @postfix_notation.count(:eql) > 1
      @variables = extract_variables
      update_sha1
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
      update_sha1
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

    def update_sha1
      @sha1 = Digest::SHA1.hexdigest([@postfix_notation, @variables].map(&:inspect).join('-'))
    end

  end

end
